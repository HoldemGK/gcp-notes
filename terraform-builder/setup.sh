#!/bin/bash

#enable APIs
gcloud services enable sourcerepo.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud app create --region=$REGION
