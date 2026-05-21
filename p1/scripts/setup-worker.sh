#!/bin/bash
set -e
sudo -E apt-get update
sudo -E apt-get install -y -q curl

while [ ! -f /vagrant/node-token ]; do
  echo "Waiting for /vagrant/node-token file..."
  sleep 2
done

mkdir -p /home/vagrant/.ssh
if [ -f /vagrant/controller_id_rsa.pub ]; then
    cat /vagrant/controller_id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
    chmod 700 /home/vagrant/.ssh
    chmod 600 /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
fi

TOKEN_VALUE=$(cat /vagrant/node-token)

curl -sfL https://get.k3s.io | \
  K3S_URL=https://192.168.56.110:6443 \
  K3S_TOKEN=$TOKEN_VALUE \
  INSTALL_K3S_EXEC="--node-name dabaeSW --node-ip 192.168.56.111" \
  sh -s - agent
