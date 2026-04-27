#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get update
sudo -E apt-get install -y -q curl

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 \
  K3S_TOKEN_FILE=/vagrant/node-token \
  sh -s - agent

mkdir -p /home/vagrant/.ssh
if [ -f /vagrant/controller_id_rsa.pub ]; then
    cat /vagrant/controller_id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
    chmod 700 /home/vagrant/.ssh
    chmod 600 /home/vagrant/.ssh/authorized_keys
    chown -R vagrant:vagrant /home/vagrant/.ssh
fi