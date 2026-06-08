#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GITLAB_MANIFEST="${PROJECT_ROOT}/confs/gitlab.yaml"

kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "$GITLAB_MANIFEST"

if [ ! -f ~/.ssh/id_rsa_argocd ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N "" <<< y
fi

echo "Waiting for GitLab to be ready (omnibus reconfigure can take 5-15 minutes)..."
kubectl rollout status deployment/gitlab -n gitlab --timeout=35m

echo "✅ GitLab deployment completed successfully!"
