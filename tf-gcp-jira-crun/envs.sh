#!/bin/bash

export KEY_JSON=/home/keys/key.json
export REGION=europe-west1
export ZONE=europe-west1-b
export TIER=db-n1-standard-1
export SQL_INST_NAME=mysql-jira-instance
export PROJECT=$(gcloud info --format='value(config.project)')
export SA_NAME=jira-service-account
export SA_ROLE="roles/cloudsql.client"
export SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:jira-service-account" \
    --format='value(email)')
export TAG="8.2.4"
export JIRA_IMAGE=atlassian/jira-software:${TAG}
export GCR_IMAGE=gcr.io/${PROJECT}/jira:${TAG}

# TERRAFORM SPECIFIC ENV VARS - EQUAL TO THE ONES ABOVE, JUST NAMED DIFFERENTLY
export TF_VAR_key=${KEY_JSON}
export TF_VAR_jira_image=${JIRA_IMAGE}
export TF_VAR_sql_inst_name=${SQL_INST_NAME}
export TF_VAR_region=${REGION}
export TF_VAR_zone=${ZONE}
export TF_VAR_tier=${TIER}
export TF_VAR_project=${PROJECT}
export TF_VAR_sa_name=${SA_NAME}
export TF_VAR_sa_role=${SA_ROLE}
export TF_VAR_sa_email=${SA_EMAIL}
export TF_VAR_gcr_image=${GCR_IMAGE}
