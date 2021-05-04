#!/bin/bash

export REGION=us-east1
export ZONE=${REGION}-b
export PROJECT_ID=$(gcloud info --format='value(config.project)')

# Call the function statusCheck to validate the environment
statusCheck "$REGION" "REGION"
statusCheck "$ZONE" "ZONE"
statusCheck "$PROJECT_ID" "PROJECT_ID"
