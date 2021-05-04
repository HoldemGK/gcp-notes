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
git push google main
