#!/bin/bash
set -e
sudo apt-get update
sudo apt-get install -y -q openssh-client curl

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-name dabaeS \
  --node-ip 192.168.56.110 \
  --bind-address 192.168.56.110 \
  --advertise-address 192.168.56.110 \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --disable metrics-server" sh -

if ! grep -q "alias k=" /home/vagrant/.bashrc; then
  echo 'alias k="kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml"' >> /home/vagrant/.bashrc
  echo 'source <(kubectl completion bash)'                         >> /home/vagrant/.bashrc
  echo 'complete -F __start_kubectl k'                             >> /home/vagrant/.bashrc
fi

mkdir -p /home/vagrant/.ssh 
if [ ! -f /home/vagrant/.ssh/id_rsa.pub ]; then
  ssh-keygen -q -t rsa -N "" -f /home/vagrant/.ssh/id_rsa
fi

chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700  /home/vagrant/.ssh
chmod 600  /home/vagrant/.ssh/id_rsa
chmod 644  /home/vagrant/.ssh/id_rsa.pub
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/controller_id_rsa.pub

echo "En attente de la génération du node-token par K3s..."
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 1
done

sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token
chmod 644 /vagrant/node-token