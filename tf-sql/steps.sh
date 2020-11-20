# Cloud SQL with Terraform

export PROJECT=$(gcloud config get-value project)
export ZONE=us-central1
terraform version

git clone https://github.com/HoldemGK/gcp-notes.git
cd gcp-notes/tf-sql

terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Installing the Cloud SQL Proxy
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy
chmod +x cloud_sql_proxy

DB_NAME=$(terraform output -json | jq -r '.instance_name.value')
CONN_NAME="${PROJECT}:${ZONE}:${DB_NAME}"

./cloud_sql_proxy -instances=${CONN_NAME}=tcp:3306

echo PASSWORD=$(terraform output -json | jq -r '.generated_user_password.value')
mysql -u default -p $PASSWORD --host 127.0.0.1 default
