export PROJECT=$DEVSHELL_PROJECT_ID
export REGION=us-central1
export ZONE=$REGION-a
gcloud compute instances create source-vm --zone=$ZONE \
  --machine-type=e2-standard-2 --subnet=default --scopes="cloud-platform" \
  --tags=http-server,https-server \
  --image=ubuntu-minimal-1604-xenial-v20210119a \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB --boot-disk-type=pd-standard \
  --boot-disk-device-name=source-vm \
  --metadata startup-script='#! /bin/bash
  sudo su -
  apt-get update
  apt-get install -y apache2
  cat <<EOF > /var/www/html/index.html
  <html><body><h1>Hello World</h1>
  <p>This page was created from a simple start up script!</p>
  </body></html>
  EOF'

gcloud compute firewall-rules create default-allow-http --direction=INGRESS \
  --priority=1000 --network=default --action=ALLOW --rules=tcp:80 \
  --source-ranges=0.0.0.0/0 --target-tags=http-server

# Create a processing cluster
gcloud container clusters create migration-processing --project=$PROJECT \
  --zone=$ZONE --machine-type=e2-standard-4 \
  --image-type=ubuntu_containerd --num-nodes=3 \
  --enable-stackdriver-kubernetes \
  --subnetwork="projects/${PROJECT}/regions/${REGION}/subnetworks/default" \
  --cluster-version=1.19.12-gke.2101

## create a service account with the storage.admin role
gcloud iam service-accounts create m4a-install --project=$PROJECT
gcloud projects add-iam-policy-binding $PROJECT \
  --member="serviceAccount:m4a-install@${PROJECT}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"
gcloud iam service-accounts keys create m4a-install.json \
  --iam-account=m4a-install@${PROJECT}.iam.gserviceaccount.com \
  --project=$PROJECT

## Connect to the cluster
gcloud container clusters get-credentials migration-processing --zone=$ZONE
## Set up Migrate for Anthos components
migctl setup install --json-key=m4a-install.json
migctl doctor

# Migrating the VM
gcloud iam service-accounts create m4a-ce-src --project=$PROJECT
gcloud projects add-iam-policy-binding $PROJECT \
  --member="serviceAccount:m4a-ce-src@${PROJECT}.iam.gserviceaccount.com" \
  --role="roles/compute.viewer"
gcloud projects add-iam-policy-binding $PROJECT \
  --member="serviceAccount:m4a-ce-src@${PROJECT}.iam.gserviceaccount.com" \
  --role="roles/compute.storageAdmin"
gcloud iam service-accounts keys create m4a-ce-src.json \
  --iam-account=m4a-ce-src@${PROJECT}.iam.gserviceaccount.com \
  --project=$PROJECT

## Create the migration source
migctl source create ce source-vm --project $PROJECT --json-key=m4a-ce-src.json

# Create a migration
migctl migration create my-migration \
  --source source-vm --vm-id source-vm --intent Image

migctl migration status my-migration
migctl migration get my-migration

# Migrate the VM using the migration plan
migctl migration generate-artifacts my-migration
migctl migration status my-migration -v

# Deploying the migrated workload
migctl migration get-artifacts my-migration
kubectl apply -f deployment_spec.yaml
kubectl get service
