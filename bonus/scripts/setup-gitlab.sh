cat > ~/inception-of-things-dabae/bonus/scripts/setup-gitlab.sh << 'EOF'
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONUS_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Déploiement de GitLab via image Docker directe..."
kubectl apply -f "${BONUS_DIR}/confs/gitlab-deployment.yaml"

echo "==> Génération de la clé SSH pour ArgoCD..."
if [ ! -f ~/.ssh/id_rsa_argocd ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N ""
fi
EOF
chmod +x ~/inception-of-things-dabae/bonus/scripts/setup-gitlab.sh