#!/bin/bash

set -e

echo "🚀 Starting VM Setup to run part 3..."

# 1. Update system and install base requirements
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 2. Install Docker
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
fi

# 3. Install k3d
if ! command -v k3d &> /dev/null; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# 4. Install kubectl
if ! command -v kubectl &> /dev/null; then
    K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
fi

# 5. Add aliases to .bashrc
if ! grep -q "alias k=" ~/.bashrc; then
    echo "⌨️ Adding aliases (k=kubectl)..."
    echo 'alias k="kubectl"' >> ~/.bashrc
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
    echo 'complete -F __start_kubectl k' >> ~/.bashrc
fi
