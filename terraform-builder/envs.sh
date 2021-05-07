#!/bin/bash

export REGION=us-east1
export ZONE=${REGION}-b
export PROJECT_ID=$(gcloud info --format='value(config.project)')
export REPO_NAME=terraform-builder
#Or hardcode on anover emails
export SENDER=$(gcloud info --format='value(config.account)')
export RECIPIENT=$(gcloud info --format='value(config.account)')
export REPO_LINK='https://source.developers.google.com'

# Update the compute environment
gcloud config set compute/region $GCP_REGION
gcloud config set compute/zone  $GCP_ZONE

# ---  Validate environment variables - Tick/OK, Cross/Not OK
function statusCheck(){
  if [ -z "$1" ]
  then
    printf "\u274c $2\n"
  else
    printf "\u2714 $2\n"
  fi
}

# Call the function statusCheck to validate the environment
statusCheck "$REGION" "REGION"
statusCheck "$ZONE" "ZONE"
statusCheck "$PROJECT_ID" "PROJECT_ID"
statusCheck "$REPO_NAME" "REPO_NAME"
statusCheck "$SENDER" "SENDER"
statusCheck "$RECIPIENT" "RECIPIENT"
statusCheck "$REPO_LINK" "REPO_LINK"
