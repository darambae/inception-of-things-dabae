#!/bin/bash
# setup.sh — installe uniquement les outils nécessaires
set -e

echo "==> Mise à jour des paquets..."
sudo apt-get update -qq
sudo apt-get install -y curl

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

# argocd CLI (optionnel mais pratique pour les commandes argocd app sync etc.)
if ! command -v argocd &>/dev/null; then
    echo "==> Installation de la CLI ArgoCD..."
    ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep tag_name | cut -d'"' -f4)
    curl -sSL -o /tmp/argocd "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
    chmod +x /tmp/argocd
    sudo mv /tmp/argocd /usr/local/bin/argocd
fi

echo ""
echo "✅ Tous les outils sont installés."
echo "   Lance 'make' pour créer le cluster et déployer ArgoCD."