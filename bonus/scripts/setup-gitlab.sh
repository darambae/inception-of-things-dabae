#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
YAML_PATH="${PROJECT_ROOT}/confs/values.yaml"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f "$YAML_PATH" \
  --timeout 30m

ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N ""

kubectl rollout status deployment/gitlab-webservice-default -n gitlab --timeout=35m
echo "✅ GitLab deployment completed successfully!"