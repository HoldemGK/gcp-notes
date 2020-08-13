#!/bin/bash

export PROJECT_ID=$(gcloud info --format='value(config.project)')
export KEY_JSON=/home/keys/key-tf.json
export REGION=us-west1
export ZONE=us-west1-b
export SQL_INST_NAME=ps-instance
export DB_VERSION="POSTGRES_11"
export NETWORK=${PROJECT_ID}'-network'
export SUBNETWORK=${PROJECT_ID}'-subnetwork'
export PRIVATE_IP_NAME="PRIVATE_IP"
export CLUSTER_NAME="mr-cluster"

# TERRAFORM SPECIFIC ENV VARS - EQUAL TO THE ONES ABOVE, JUST NAMED DIFFERENTLY
export TF_VAR_project_id=${PROJECT_ID}
export TF_VAR_key=${KEY_JSON}
export TF_VAR_region=${REGION}
export TF_VAR_zone=${ZONE}
export TF_VAR_sql_inst_name=${SQL_INST_NAME}
export TF_VAR_db_version=${DB_VERSION}
export TF_VAR_network=${NETWORK}
export TF_VAR_subnetwork=${SUBNETWORK}
export TF_VAR_private_ip_name=${PRIVATE_IP_NAME}
export TF_VAR_cluster_name=${CLUSTER_NAME}
