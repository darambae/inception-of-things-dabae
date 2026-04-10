#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get update
sudo -E apt-get install -y -q curl

curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable metrics-server \
  --disable-cloud-controller

if ! grep -q "alias k=" /home/vagrant/.bashrc; then
    echo 'alias k="kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml"' >> /home/vagrant/.bashrc
    echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
    echo 'complete -F __start_kubectl k' >> /home/vagrant/.bashrc
fi

kubectl apply -f /vagrant/apps.yaml