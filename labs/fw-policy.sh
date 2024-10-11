export REGION="us-central1"
export ZONE="us-central1-a"

# Create a custom VPC network with subnets
gcloud compute networks create vpc-fw-rules \
  --subnet-mode=custom \
  --description="VPC network for the firewall rules tutorial"

gcloud compute networks subnets create subnet-fw-rules-server \
  --network=vpc-fw-rules \
  --region=${REGION} \
  --range=10.0.0.0/24 \
  --enable-private-ip-google-access

gcloud compute networks subnets create subnet-fw-rules-client \
  --network=vpc-fw-rules \
  --region=${REGION} \
  --range=192.168.10.0/24 \
  --enable-private-ip-google-access

# Create client and server VMs
gcloud compute instances create vm-fw-rules-server \
  --network=vpc-fw-rules \
  --zone=${ZONE} \
  --subnet=subnet-fw-rules-server \
  --stack-type=IPV4_ONLY \
  --no-address

gcloud compute instances create vm-fw-rules-client \
  --network=vpc-fw-rules \
  --zone=${ZONE} \
  --subnet=subnet-fw-rules-client \
  --stack-type=IPV4_ONLY \
  --no-address

# Create a Cloud Router and a Cloud NAT gateway
gcloud compute routers create router-fw-rules \
  --network=vpc-fw-rules \
  --region=${REGION}

gcloud compute routers nats create gateway-fw-rules \
  --router=router-fw-rules \
  --region=${REGION} \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges

# Create a global network firewall policy
gcloud compute network-firewall-policies create fw-policy --global
gcloud compute network-firewall-policies rules create 65534 \
  --firewall-policy=fw-policy \
  --direction=EGRESS \
  --action=ALLOW \
  --dest-ip-ranges=0.0.0.0/0 \
  --layer4-configs=all \
  --global-firewall-policy \
  --enable-logging

gcloud compute network-firewall-policies associations create \
  --firewall-policy=fw-policy \
  --network=vpc-fw-rules \
  --name=pol-association-fw-rules \
  --global-firewall-policy

gcloud compute network-firewall-policies rules create 500 \
  --firewall-policy=fw-policy \
  --direction=INGRESS \
  --action=ALLOW \
  --src-ip-ranges=35.235.240.0/20 \
  --global-firewall-policy \
  --layer4-configs tcp:22,tcp:3389 \
  --enable-logging

# Install the Apache server
sudo apt update && sudo apt -y install apache2
sudo systemctl status apache2 --no-pager
echo '<!doctype html><html><body><h1>Hello World!</h1></body></html>' | sudo tee /var/www/html/index.html

# Update the global network firewall policy to allow internal traffic
gcloud compute network-firewall-policies rules create 501 \
  --firewall-policy=fw-policy \
  --direction=INGRESS \
  --action=ALLOW \
  --src-ip-ranges=192.168.10.0/24 \
  --dest-ip-ranges=10.0.0.0/24 \
  --layer4-configs=all \
  --global-firewall-policy \
  --enable-logging