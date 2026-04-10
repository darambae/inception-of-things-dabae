#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get update
sudo -E apt-get install -y -q openssh-client curl

curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --disable metrics-server \
  --disable-cloud-controller

if ! grep -q "alias k=" /home/vagrant/.bashrc; then
    echo 'alias k="kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml"' >> /home/vagrant/.bashrc
    echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc
    echo 'complete -F __start_kubectl k' >> /home/vagrant/.bashrc
fi

mkdir -p /home/vagrant/.ssh
if [ ! -f /home/vagrant/.ssh/id_rsa.pub ]; then
    ssh-keygen -q -t rsa -N "" -f /home/vagrant/.ssh/id_rsa
fi

sudo chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/id_rsa
chmod 644 /home/vagrant/.ssh/id_rsa.pub

cp /home/vagrant/.ssh/id_rsa.pub /vagrant/controller_id_rsa.pub

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token