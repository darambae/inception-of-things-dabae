#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GITLAB_CONFIG="${PROJECT_ROOT}/confs/values.yaml"
PSQL_CONFIG="${PROJECT_ROOT}/confs/postgresql.yaml"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

helm repo add gitlab https://charts.gitlab.io/
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install gitlab-redis bitnami/redis \
  --namespace gitlab \
  --set auth.enabled=false \
  --set architecture=standalone \
  --wait --timeout 15m

kubectl apply -n gitlab -f "$PSQL_CONFIG"

kubectl create secret generic gitlab-objectstorage-secret \
  --namespace gitlab \
  --from-literal=connection="" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic gitlab-postgresql-password \
  --namespace gitlab \
  --from-literal=postgresql-password=gitlabpassword \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl wait --for=condition=available deployment/gitlab-postgresql -n gitlab --timeout=10m

CRDS=(
  "backendtlspolicies.gateway.networking.k8s.io"
  "referencegrants.gateway.networking.k8s.io"
  "gatewayclasses.gateway.networking.k8s.io"
  "grpcroutes.gateway.networking.k8s.io"
  "httproutes.gateway.networking.k8s.io"
  "gateways.gateway.networking.k8s.io"
)

echo "==> Checking and deleting Gateway API CRDs if they exist..."

for crd in "${CRDS[@]}"; do
  if kubectl get crd "$crd" &>/dev/null; then
    echo "Found CRD: $crd. Deleting..."
    kubectl delete crd "$crd"
  else
    echo "CRD not found: $crd (Skipping)"
  fi
done
echo "==> CRD cleanup process completed completed cleanly!"

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f "$GITLAB_CONFIG" \
  --timeout 30m

ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N "" <<< y

echo "En attente que GitLab soit pret..."
kubectl wait --for=condition=available deployment/gitlab-webservice-default \
    -n gitlab \
    --timeout=35m

echo "✅ Deploiement de GitLab termine avec succes !"