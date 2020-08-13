#!/bin/bash

export KEY_JSON=/home/keys/key-tf.json
export REGION=us-west1
export ZONE=us-west1-b
export SQL_INST_NAME=ps-instance
export PROJECT_ID=$(gcloud info --format='value(config.project)')
export DB_VERSION="POSTGRES_11"
export NETWORK=${PROJECT_ID}'-network'
export SUBNETWORK=${PROJECT_ID}'-subnetwork'

# TERRAFORM SPECIFIC ENV VARS - EQUAL TO THE ONES ABOVE, JUST NAMED DIFFERENTLY
export TF_VAR_key=${KEY_JSON}
export TF_VAR_region=${REGION}
export TF_VAR_zone=${ZONE}
export TF_VAR_sql_inst_name=${SQL_INST_NAME}
export TF_VAR_project_id=${PROJECT_ID}
export TF_VAR_db_version=${DB_VERSION}
export TF_VAR_network=${NETWORK}
export TF_VAR_subnetwork=${SUBNETWORK}
