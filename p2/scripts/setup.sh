#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get update
sudo -E apt-get install -y -q curl

curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable metrics-server \
  --node-ip=192.168.56.110 \
  --flannel-iface=eth1 \
  --disable-cloud-controller

if ! grep -q "alias k=" /home/vagrant/.bashrc; then
    echo 'alias k="kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml"' >> /home/vagrant/.bashrc
    echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
    echo 'complete -F __start_kubectl k' >> /home/vagrant/.bashrc
fi

echo "==> Attente de k3s..."
until kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes &>/dev/null; do
    sleep 2
done
echo "==> k3s prêt !"

kubectl apply -f /vagrant/confs/apps.yaml