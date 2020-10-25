source envs.sh
terraform version
git clone https://github.com/GoogleCloudPlatform/terraform-google-lb-http.git
cd ~/terraform-google-lb-http/examples/multi-backend-multi-mig-bucket-https-lb
terraform init
terraform plan --out=tfplan 'project=${PROJECT}'
terraform apply tfplan
EXTERNAL_IP=$(terraform output | grep load-balancer-ip | cut -d = -f2 | xargs echo -n)
echo https://${EXTERNAL_IP}
