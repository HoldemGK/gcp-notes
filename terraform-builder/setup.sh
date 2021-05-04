#!/bin/bash

#enable APIs
gcloud services enable sourcerepo.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud app create --region=$REGION

#create the source repo to slave off the github repo
gcloud source repos create ${REPO_NAME}
git config --global credential.https://sourcedevelopers.google.com.helper gcloud.sh
git remote add google https://source.developers.google.com/p/${PROJECT_ID}/r/${REPO_NAME}
git push google master

#create the build trigger in cloud build
gcloud beta builds triggers create cloud-source-repositoies \
  --build-config=cloudbuild.yaml --repo=${REPO_NAME} \
  --branch-pattern=^master$ --description="terraform-builder-trigger"

#disable the trigger, we will run it from cloud functions
gcloud beta builds triggers export terraform-builder-trigger --destination=../cloudbuilder.yaml
echo disabled: True >> ../cloudbuilder.yaml
gcloud beta builds triggers import --source=../cloudbuilder.yaml
