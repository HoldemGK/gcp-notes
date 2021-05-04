#!/bin/bash
# ---  Validate environment variables - Tick/OK, Cross/Not OK
function statusCheck(){
  if [ -z "$1" ]
  then
    printf "\u274c $2\n"
  else
    printf "\u2714 $2\n"
  fi
}

export REGION=us-east1
export ZONE=${REGION}-b
export PROJECT_ID=$(gcloud info --format='value(config.project)')

# Call the function statusCheck to validate the environment
statusCheck "$REGION" "REGION"
statusCheck "$ZONE" "ZONE"
statusCheck "$PROJECT_ID" "PROJECT_ID"
