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

export KEY_JSON="/home/keys/key.json"
export REGION="us-east1"
export ZONE="${REGION}-b"
export BACK_BACKET="back-backet"
export PREFIX="tf-state"
export PROJECT=$(gcloud info --format='value(config.project)')
export REPOSITORY_NAME=
export BRANCH_NAME="master"
export CONTAINER_PORT=80
export IMAGE_NAME=
export DB_INSTANCE_NAME=
export DB_NAME=
export DB_USERNAME=
export DB_PASSWORD="secretP@22"
export DB_TIER="db-f1-micro"
export DB_USER_HOST=

statusCheck "$KEY_JSON" "KEY_JSON"
statusCheck "$REGION" "REGION"
statusCheck "$ZONE" "ZONE"
statusCheck "$BACK_BACKET" "BACK_BACKET"
statusCheck "$PREFIX" "PREFIX"
statusCheck "$PROJECT" "PROJECT"
statusCheck "$REPOSITORY_NAME" "REPOSITORY_NAME"
statusCheck "$BRANCH_NAME" "BRANCH_NAME"
statusCheck "$CONTAINER_PORT" "CONTAINER_PORT"
statusCheck "$IMAGE_NAME" "IMAGE_NAME"
statusCheck "$DB_INSTANCE_NAME" "DB_INSTANCE_NAME"
statusCheck "$DB_NAME" "DB_NAME"
statusCheck "$DB_USERNAME" "DB_USERNAME"
statusCheck "$DB_PASSWORD" "DB_PASSWORD"
statusCheck "$DB_TIER" "DB_TIER"
statusCheck "$DB_USER_HOST" "DB_USER_HOST"

export TF_VAR_key=${KEY_JSON}
export TF_VAR_server_name=${SERVER_NAME}
export TF_VAR_region=${REGION}
export TF_VAR_zone=${ZONE}
export TF_VAR_back_backet=${BACK_BACKET}
export TF_VAR_prefix=${PREFIX}
export TF_VAR_project=${PROJECT}
export TF_VAR_repository_name=${REPOSITORY_NAME}
export TF_VAR_branch_name=${BRANCH_NAME}
export TF_VAR_container_port=${CONTAINER_PORT}
export TF_VAR_image_name=${IMAGE_NAME}
export TF_VAR_db_instance_name=${DB_INSTANCE_NAME}
export TF_VAR_db_name=${DB_NAME}
export TF_VAR_db_username=${DB_USERNAME}
export TF_VAR_db_password=${DB_PASSWORD}
export TF_VAR_db_tier=${DB_TIER}
export TF_VAR_db_user_host=${DB_USER_HOST}
