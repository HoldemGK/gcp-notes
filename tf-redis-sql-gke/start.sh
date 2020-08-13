#!/bin/bash
gcloud config set compute/region $REGION
gcloud services enable \
    cloudapis.googleapis.com \
    cloudresourcemanager.googleapis.com \
    container.googleapis.com \
    containerregistry.googleapis.com \
    iam.googleapis.com \
    redis.googleapis.com \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com

gcloud iam service-accounts create tf-adm \
        --description="Terraform Service Account" \
        --display-name="Terraform"

gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member serviceAccount:tf-adm@$PROJECT_ID.iam.gserviceaccount.com \
        --role roles/owner

gcloud iam service-accounts keys create key-tf.json --iam-account=tf-adm@$PROJECT_ID.iam.gserviceaccount.com --project $PROJECT_ID
mv key-tf.json ~/
