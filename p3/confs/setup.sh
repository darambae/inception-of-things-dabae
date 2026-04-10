#!/bin/bash
set -e

sudo apt update
sudo apt install -y curl

# 1. Install Docker (The Simple way, with a check)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
fi

# 2. Install k3d
if ! command -v k3d &> /dev/null; then
    echo "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# 3. Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
fi

k3d cluster create me-cluster --agents 2 -p "8080:80@loadbalancer" -p "8888:8888@loadbalancer"

kubectl create namespace argocd
kubectl create namespace dev

kubectl apply -n argocd -f application.yaml
kubectl port-forward svc/argocd-server -n argocd 8443:443