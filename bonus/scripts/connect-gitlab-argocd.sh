#!/bin/bash

set -e

GREEN='\033[0;32m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONUS_DIR="$SCRIPT_DIR/../../inception-of-things-bonus"

echo -e "${GREEN}Setting up ArgoCD & Injecting SSH Key...${RESET}"

if [ ! -f ~/.ssh/id_rsa_argocd ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N ""
fi

TOOLBOX_POD=$(kubectl get pods -n gitlab -o custom-columns=NAME:.metadata.name --no-headers | grep toolbox | head -n 1)

PUB_KEY=$(cat ~/.ssh/id_rsa_argocd.pub)

kubectl exec -i -n gitlab "$TOOLBOX_POD" -- env PUB_KEY="$PUB_KEY" gitlab-rails runner "
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

ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
argocd login 127.0.0.1:9443 --username admin --password "$ARGOCD_PWD" --insecure

argocd repo add git@gitlab-gitlab-shell.gitlab.svc.cluster.local:root/inception-of-things-bonus.git \
    --ssh-private-key-path ~/.ssh/id_rsa_argocd \
    --insecure-ignore-host-key \
    --server 127.0.0.1:9443 || echo "⚠️ Repo already exists"

echo -e "${GREEN}Initializing Git repository and pushing code...${RESET}"

mkdir -p "$BONUS_DIR"
cp -r "$SCRIPT_DIR"/* "$BONUS_DIR/" 2>/dev/null || true

cd "$BONUS_DIR"

if [ ! -d ".git" ]; then
    git init --initial-branch=main
fi

git config user.email "dabae@gmail.com"
git config user.name "daram bae"

GITLAB_USER="root"
GITLAB_PASS=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode)
ENCODED_PASS=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$GITLAB_PASS")

GITLAB_HTTP_URL="http://${GITLAB_USER}:${ENCODED_PASS}@gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git"

git remote remove origin 2>/dev/null || true
git remote add origin "$GITLAB_HTTP_URL"

git add .
git commit -m "Initial commit" --allow-empty

git push -u origin main --force

echo -e "${GREEN}Applying ArgoCD Application yaml...${RESET}"
cd "$SCRIPT_DIR"
kubectl apply -f confs/application.yaml

echo -e "${GREEN}🎉 All Infrastructure Setup Completed Successfully!${RESET}"