# Terraform Redis CloudSQL GKE

## CLI setup
```
export PROJECT_ID=my_gcp_project
export ACCOUNT_ID=$(gcloud beta billing accounts list | grep True | cut -d ' ' -f1)
gcloud auth login
gcloud projects create $PROJECT_ID
gcloud config set compute/region us-east1
gcloud config set project $PROJECT_ID
gcloud beta billing projects link $PROJECT_ID --billing-account=$ACCOUNT_ID
# enable apis
gcloud services enable \
    cloudapis.googleapis.com \
    cloudresourcemanager.googleapis.com \
    container.googleapis.com \
    containerregistry.googleapis.com \
    iam.googleapis.com \
    redis.googleapis.com \
    servicenetworking.googleapis.com \
    sqladmin.googleapis.com

# If you want to use gcs for remote storage
gsutil mb -c standard -l us-east1 gs://$PROJECT_ID

# Create a service account for terraform
gcloud iam service-accounts create terraform \
    --description="Terraform Service Account" \
    --display-name="Terraform"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com \
      --role roles/owner
gcloud iam service-accounts keys create key-tf.json --iam-account=terraform@$PROJECT_ID.iam.gserviceaccount.com --project $PROJECT_ID
mv key-tf.json terraform/
```
