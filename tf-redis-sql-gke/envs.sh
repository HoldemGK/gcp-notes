#!/bin/bash

export PROJECT_ID=$(gcloud info --format='value(config.project)')
export KEY_JSON=/home/keys/key-tf.json
export REGION=us-west1
export ZONE=us-west1-b
# Cloud SQL Network
export SQL_INST_NAME=ps-instance
export DB_VERSION="POSTGRES_11"
export NETWORK=${PROJECT_ID}'-network'
export SUBNETWORK=${PROJECT_ID}'-subnetwork'
export PRIVATE_IP_NAME="sql-private-ip"
export PURPOSE="VPC_PEERING"
export ADDRESS_TYPE="INTERNAL"
export PREFIX_LENGTH=16
export DB_INSTANCE_TIER="db-custom-1-3840"
# GKE pref
export CLUSTER_NAME="mr-cluster"
export MCE_START_TIME="05:00"
export POOL_MACHINE_TYPE="n1-standard-2"
export MIN_COUNT=1
export MAX_COUNT=10
export DISK_SIZE_GB=50
# Redis pref
export REDIS_NAME="mr-redis"
export REDIS_VERSION="REDIS_5_0"
export REDIS_SIZE=1
export REDIS_TIER="STANDARD"

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
export TF_VAR_mce_start_time=${MCE_START_TIME}
export TF_VAR_pool_machine_type=${POOL_MACHINE_TYPE}
export TF_VAR_min_count=${MIN_COUNT}
export TF_VAR_max_count=${MAX_COUNT}
export TF_VAR_disk_size_gb=${DISK_SIZE_GB}
export TF_VAR_redis_name=${REDIS_NAME}
export TF_VAR_redis_version=${REDIS_VERSION}
export TF_VAR_redis_size=${REDIS_SIZE}
export TF_VAR_redis_tier=${REDIS_TIER}
export TF_VAR_purpose=${PURPOSE}
export TF_VAR_address_type=${ADDRESS_TYPE}
export TF_VAR_prefix_length=${PREFIX_LENGTH}
export TF_VAR_db_instance_tier=${DB_INSTANCE_TIER}
