#!/bin/bash
set -e

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f ../confs/values.yaml \
  --timeout 30m

ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N ""

# TOOLBOX_POD=$(kubectl get pods -n gitlab -o custom-columns=NAME:.metadata.name --no-headers | grep toolbox)
# PUB_KEY=$(cat ~/.ssh/id_rsa_argocd.pub)
# kubectl exec -it -n gitlab $TOOLBOX_POD -- \
#     gitlab-rails runner "user = User.find_by_username('root'); \
#     key = Key.new(title: 'argocd-ssh-key', key: '$PUB_KEY', user: user); \
#     if key.save; puts 'SSH Key Registered Successfully!'; else; puts key.errors.full_messages; end"

# ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
# argocd login 127.0.0.1:9443 --username admin --password "$ARGOCD_PWD" --insecure
# argocd repo add git@gitlab-gitlab-shell.gitlab.svc.cluster.local:root/inception-of-things-bonus.git \
#     --ssh-private-key-path ~/.ssh/id_rsa_argocd \
#     --insecure-ignore-host-key \
#     --server 127.0.0.1:9443
# GITLAB_PWD=$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 --decode)
# cp -r inception-of-things-dabae/bonus inception-of-things-bonus
# cd ../../../inception-of-things-bonus
# git init --initial-branch=main
# git config --global user.email "dabae@gmail.com"
# git config --global user.name "daram bae"
# git remote add origin http://gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git
# git add .
# git commit -m "Initial commit"
# git push -u origin main --force

# kubectl apply -f ../confs/application.yaml