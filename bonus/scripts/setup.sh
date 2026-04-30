set -e

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  -f ../confs/values.yaml \
  --timeout 30m

# ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)
# argocd login 127.0.0.1:9443 --username admin --password "$ARGOCD_PWD" --insecure

GITLAB_PWD=$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 --decode)
git clone https://github.com/darambae/inception-of-things-dabae.git
cp -r inception-of-things-dabae/bonus inception-of-things-bonus
cd inception-of-things-bonus

git init --initial-branch=main
git remote add origin http://gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git
git add .
git commit -m "Initial commit"
git push -u origin main --force
# argocd repo add http://gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git \
#     --username root \
#     --password "$GITLAB_PWD" \
#     --insecure \
#     --server 127.0.0.1:9443

# kubectl apply -f ../confs/application.yaml