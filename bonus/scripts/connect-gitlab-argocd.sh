#!/bin/bash

set -e

GREEN='\033[0;32m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BONUS_DIR="$(cd "$PROJECT_DIR/.." && pwd)/inception-of-things-bonus"

echo -e "${GREEN}Setting up ArgoCD & Injecting SSH Key...${RESET}"

if [ ! -f ~/.ssh/id_rsa_argocd ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N ""
fi

echo "Waiting for GitLab to be ready..."
kubectl rollout status deployment/gitlab -n gitlab --timeout=10m

GITLAB_POD=$(kubectl get pods -n gitlab -l app=gitlab -o jsonpath='{.items[0].metadata.name}')

PUB_KEY=$(cat ~/.ssh/id_rsa_argocd.pub)

kubectl exec -i -n gitlab "$GITLAB_POD" -- env PUB_KEY="$PUB_KEY" gitlab-rails runner "
user = User.find_by_username('root')
if user
  key = Key.find_by(title: 'argocd-ssh-key') || Key.new(title: 'argocd-ssh-key', user: user)
  key.key = ENV['PUB_KEY']
  if key.save
    puts '🚀 SSH Key Registered Successfully'
  else
    puts key.errors.full_messages
  end
else
  puts '❌ Root user not found'
end
"
echo -e "${GREEN}Initializing Git repository and pushing code...${RESET}"

mkdir -p "$BONUS_DIR"
rsync -a --delete --exclude='.git' "$PROJECT_DIR/" "$BONUS_DIR/"

cd "$BONUS_DIR"

if [ ! -d ".git" ]; then
    git init --initial-branch=main
fi

git config user.email "dabae@gmail.com"
git config user.name "daram bae"

GITLAB_USER="root"
GITLAB_PASS=$(kubectl exec -n gitlab "$GITLAB_POD" -- grep 'Password:' /etc/gitlab/initial_root_password | awk '{print $2}')
ENCODED_PASS=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$GITLAB_PASS")

GITLAB_HTTP_URL="http://${GITLAB_USER}:${ENCODED_PASS}@gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git"

git remote remove origin 2>/dev/null || true
git remote add origin "$GITLAB_HTTP_URL"

git add .
git commit -m "Initial commit" --allow-empty
git push -u origin main

ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
argocd login 127.0.0.1:9443 --username admin --password "$ARGOCD_PWD" --insecure

argocd repo add git@gitlab.gitlab.svc.cluster.local:root/inception-of-things-bonus.git \
    --ssh-private-key-path ~/.ssh/id_rsa_argocd \
    --insecure-ignore-host-key \
    --server 127.0.0.1:9443

echo -e "${GREEN}Applying ArgoCD Application yaml...${RESET}"

kubectl apply -f "./bonus/confs/application.yaml"

echo -e "${GREEN}🎉 All Infrastructure Setup Completed Successfully!${RESET}"