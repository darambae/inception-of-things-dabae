#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
YAML_PATH="${PROJECT_ROOT}/confs/values.yaml"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

helm repo add gitlab https://charts.gitlab.io/
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add minio https://operator.min.io/
helm repo update

helm upgrade --install gitlab-postgresql bitnami/postgresql \
  --namespace gitlab \
  --set global.postgresql.auth.username=gitlab \
  --set global.postgresql.auth.password=gitlabpassword \
  --set global.postgresql.auth.database=gitlabhq_production \
  --set image.tag=17

helm upgrade --install gitlab-redis bitnami/redis \
  --namespace gitlab \
  --set auth.enabled=false \
  --set architecture=standalone \
  --wait --timeout 15m

kubectl create secret generic gitlab-postgresql-password \
  --namespace gitlab \
  --from-literal=postgresql-password="gitlabpassword" \
  --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install gitlab-minio bitnami/minio \
  --namespace gitlab \
  --set auth.rootUser=minioadmin \
  --set auth.rootPassword=minioadminpassword \
  --set defaultBuckets="gitlab-artifacts gitlab-lfs gitlab-uploads gitlab-packages gitlab-backups gitlab-pseudo"

kubectl create secret generic gitlab-objectstorage-secret \
  --namespace gitlab \
  --from-literal=accesskey="minioadmin" \
  --from-literal=secretkey="minioadminpassword" \
  --dry-run=client -o yaml | kubectl apply -f -
  
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f "$YAML_PATH" \
  --timeout 30m

ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N "" <<< y

echo "Waiting for GitLab to be ready..."
kubectl wait --for=condition=available deployment/gitlab-webservice-default \
    -n gitlab \
    --timeout=35m

echo "✅ GitLab deployment completed successfully!"