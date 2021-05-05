#!/bin/bash

#enable APIs
gcloud services enable sourcerepo.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud app create --region=${REGION}

#create the source repo to slave off the github repo
gcloud source repos create ${REPO_NAME}
git config --global credential.https://sourcedevelopers.google.com.helper gcloud.sh
git remote add google https://source.developers.google.com/p/${PROJECT_ID}/r/${REPO_NAME}
git push google master

#create the build trigger in cloud build
gcloud beta builds triggers create cloud-source-repositories \
  --build-config=cloudbuild.yaml --repo=${REPO_NAME} \
  --branch-pattern=^master$ --description="terraform-builder-trigger"

#disable the trigger, we will run it from cloud functions
gcloud beta builds triggers export terraform-builder-trigger --destination=../cloudbuilder.yaml
echo disabled: True >> ../cloudbuilder.yaml
gcloud beta builds triggers import --source=../cloudbuilder.yaml

# create pub sub
gcloud pubsub topics create terraform-build-topic

# create cloud functions service account
gcloud iam service-accounts create terraform-builder --description="Cloud Function's Service Account to trigger build" --display-name="Terraform Builder"

#give Service account required perms
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:terraform-builder@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/cloudbuild.builds.editor

#create cloud function
gcloud functions deploy terraform-builder \
  --source https://source.developers.google.com/projects/${PROJECT_ID}/repos/${REPO_NAME}/moveable-aliases/master/paths/terraform-builder/cloud-function \
  --trigger-topic=terraform-build-topic --max-instances=1 \
  --memory=128MB --update-labels=terraform-builder=cloudfunction --entry-point=trigger_build \
  --runtime=python37 --service-account=terraform-builder@${PROJECT_ID}.iam.gserviceaccount.com \
  --timeout=300 --quiet

# create cron schedule
gcloud scheduler jobs create pubsub terraform-builder-cron --schedule="57 3 * * *" --topic=terraform-build-topic --message-body="gobuild"

#Set up alerting
#set up build notification, set up the topic, this should exist if container registry has ever been used
gcloud pubsub topics create gcr || true

#split out notifier
gcloud iam service-accounts create terraform-build-notifier --description="Cloud Function's Service Account for build noficiations" \
  --disable-name="Terraform Builder Notifier"
