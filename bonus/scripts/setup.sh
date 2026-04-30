set -e

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f ../confs/values.yaml \
  --timeout 30m

ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
argocd login 127.0.0.1:9443 --username admin --password "$ARGOCD_PWD" --insecure

GITLAB_PWD=$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 --decode)
argocd repo add http://gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git \
    --username root \
    --password "$GITLAB_PWD" \
    --insecure \
    --server 127.0.0.1:9443

# kubectl apply -f ../confs/application.yaml