#!/bin/bash

gcloud compute instances create master --boot-disk-size 100GB --can-ip-forward \
  --image-family ubuntu-2004-lts --image-project ubuntu-os-cloud --machine-type e2-standard-2 \
  --private-network-ip 10.0.0.11 --subnet eu-c2-k8s-nodes \
  --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
  --tags k8s,master \
  --metadata startup-script-url=gs://${BUCKET_NAME}/install-master.sh \
  --service-account admin-sa@${PROJECT}.iam.gserviceaccount.com \
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

# Bastion
gcloud compute instances create bastion --machine-type=e2-medium \
  --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=eu-c2-k8s-nodes \
  --metadata=startup-script-url=gs://${BUCKET_NAME}/bastion_boot.sh \
  --can-ip-forward --no-restart-on-failure --maintenance-policy=TERMINATE --provisioning-model=SPOT --instance-termination-action=STOP \
  --scopes=https://www.googleapis.com/auth/cloud-platform --tags=k8s,master,node \
  --service-account=admin-sa@${PROJECT}.iam.gserviceaccount.com \
  --zone=europe-central2-a

# GKE
gcloud beta container clusters create "k8s" \
  --no-enable-basic-auth --cluster-version "1.27.3-gke.100" --release-channel "stable" \
  --machine-type "e2-medium" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "50" \
  --metadata disable-legacy-endpoints=true \
  --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
  --max-pods-per-node "32" --spot --num-nodes "2" \
  --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias \
  --network "projects/${PROJECT}/global/networks/k8s-nodes" \
  --subnetwork "projects/${PROJECT}/regions/europe-central2/subnetworks/eu-c2-k8s-nodes" \
  --cluster-ipv4-cidr "192.168.0.0/21" --services-ipv4-cidr "192.168.8.0/22" \
  --no-enable-intra-node-visibility --default-max-pods-per-node "32" \
  --enable-autoscaling --total-min-nodes "1" --total-max-nodes "3" --location-policy "ANY" \
  --security-posture=standard --workload-vulnerability-scanning=disabled --no-enable-master-authorized-networks \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
  --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 \
  --binauthz-evaluation-mode=DISABLED --enable-managed-prometheus --enable-shielded-nodes \
  --node-locations "europe-central2-a" \
  --zone "europe-central2-a"