#!/bin/bash
# setup.sh — installe les outils nécessaires et configure le cluster
set -e

CLUSTER_NAME="iot-cluster"
ARGOCD_NS="argocd"
DEV_NS="dev"
APP_CONF="confs/application.yaml"

echo "==> Mise à jour des paquets..."
sudo apt-get update -q
sudo apt-get install -y curl make

# Docker
if ! command -v docker &>/dev/null; then
    echo "==> Installation de Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    echo "⚠️  Docker installé. Si c'est la première fois, relance le script après 'newgrp docker' ou reconnecte-toi."
fi

# k3d
if ! command -v k3d &>/dev/null; then
    echo "==> Installation de k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# kubectl
if ! command -v kubectl &>/dev/null; then
    echo "==> Installation de kubectl..."
    K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
fi

# Add aliases to .bashrc
if ! grep -q "alias k=" ~/.bashrc; then
    echo "⌨️ Adding aliases (k=kubectl)..."
    echo 'alias k="kubectl"' >> ~/.bashrc
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
    echo 'complete -F __start_kubectl k' >> ~/.bashrc
fi

# argocd CLI
if ! command -v argocd &>/dev/null; then
    echo "==> Installation de la CLI ArgoCD..."
    ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d'"' -f4)
    curl -sSL -o /tmp/argocd "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
    chmod +x /tmp/argocd
    sudo mv /tmp/argocd /usr/local/bin/argocd
fi

echo "✅ Tools installed. Ready for make."

# Toutes les étapes suivantes tournent dans le contexte du groupe docker
sg docker <<EOF
set -e

echo '==> Création du cluster k3d...'
if k3d cluster list | grep -q "^${CLUSTER_NAME}"; then
  echo "⚠️  Cluster '${CLUSTER_NAME}' already exists, skipping..."
else
  k3d cluster create ${CLUSTER_NAME} \
      --agents 2 \
      -p '8080:80@loadbalancer' \
      -p '8888:8888@loadbalancer'
fi

echo '==> Création des namespaces...'
kubectl create namespace ${ARGOCD_NS} --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace ${DEV_NS}    --dry-run=client -o yaml | kubectl apply -f -

echo '==> Installation d Argo CD...'
kubectl apply -n ${ARGOCD_NS} \
    --server-side \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo '==> Attente des pods Argo CD...'
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=argocd-server \
    -n ${ARGOCD_NS} \
    --timeout=10m

echo '==> Configuration de l application ArgoCD...'
kubectl apply -f ${APP_CONF}

echo '==> Mot de passe Argo CD (user: admin) :'
kubectl -n ${ARGOCD_NS} get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d && echo
EOF

echo '==> UI ArgoCD dispo sur : https://argocd-iot.com:9443'
nohup kubectl port-forward --address 0.0.0.0 svc/argocd-server -n ${ARGOCD_NS} 9443:443 > /dev/null 2>&1 &