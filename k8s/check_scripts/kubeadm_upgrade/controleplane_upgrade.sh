#!/bin/bash

sudo apt-get update
sudo apt-get install -y --allow-change-held-packages kubeadm=1.27.2-00

kubectl drain acgk8s-control --ignore-daemonsets

sudo kubeadm upgrade plan v1.27.2
sudo kubeadm upgrade apply v1.27.2 -y

sudo apt-get install -y --allow-change-held-packages kubelet=1.27.2-00 kubectl=1.27.2-00
sudo systemctl daemon-reload
sudo systemctl restart kubelet

kubectl uncordon acgk8s-control

# Prepare Node Upgrade
kubectl drain ${NODE} --ignore-daemonsets --force
scp nodes_upgrade.sh ${USER}@${NODE}:${HOME}
ssh ${USER}@${NODE}
kubectl uncordon acgk8s-worker1