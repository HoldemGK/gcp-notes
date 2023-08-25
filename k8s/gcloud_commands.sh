#!/bin/bash

gcloud compute instances create master --boot-disk-size 100GB --can-ip-forward \
  --image-family ubuntu-2004-lts --image-project ubuntu-os-cloud --machine-type e2-standard-2 \
  --private-network-ip 10.0.0.11 --subnet eu-c2-k8s-nodes \
  --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
  --tags k8s,master \
  --metadata startup-script-url=gs://gk-k8s-install-script/install-master.sh \
  --zone europe-central2-b

# Nodes MIG
gcloud beta compute instance-groups managed create node-group \
  --base-instance-name=node-group --base-instance-name=node \
  --size=1 --template=node-tmpl-6 \
  --health-check=node-hc --initial-delay=200 --force-update-on-repair \
   --zone=europe-central2-b

gcloud beta compute instance-groups managed set-autoscaling node-group  \
  --cool-down-period=40 --max-num-replicas=4 --min-num-replicas=1 \
  --mode=on --target-cpu-utilization=0.8 \
  --zone=europe-central2-b