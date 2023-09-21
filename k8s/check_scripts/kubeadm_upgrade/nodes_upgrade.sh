#!/bin/bash

sudo apt-get update
sudo apt-get install -y --allow-change-held-packages kubeadm=1.27.2-00

sudo kubeadm upgrade node

sudo apt-get install -y --allow-change-held-packages kubelet=1.27.2-00 kubectl=1.27.2-00
sudo systemctl daemon-reload
sudo systemctl restart kubelet

exit