# Using Private Service Connect to publish and consume services
gcloud config list project
export PROD_PROJ="prod-pj"
export CONSUMER_PROJ="consumer-pj"
gcloud config set project $PROD_PROJ

# Create Producers VPC network
# VPC Network
gcloud compute networks create vpc-demo-producer --project=$PROD_PROJ --subnet-mode=custom
gcloud compute networks subnets create vpc-demo-us-west2 --project=$PROD_PROJ \
  --range=10.0.2.0/24 --network=vpc-demo-producer --region=us-west2

# Create Cloud NAT instance
gcloud compute routers create crnatprod --network=vpc-demo-producer --region=us-west2
gcloud compute routers nats create cloudnatprod --router=crnatprod \
  --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges \
  --enable-logging --region=us-west2

# Create compute instances
gcloud compute instances create www-01 \
  --zone=us-west2-a \
  --image-family=debian-9 \
  --image-project=debian-cloud \
  --subnet=vpc-demo-us-west2 --no-address \
  --metadata-from-file=startup-script="./startup-www.sh"

  gcloud compute instances create www-02 \
    --zone=us-west2-a \
    --image-family=debian-9 \
    --image-project=debian-cloud \
    --subnet=vpc-demo-us-west2 --no-address \
    --metadata-from-file=startup-script="./startup-www.sh"

# Create unmanaged instance group
gcloud compute instance-groups unmanaged create vpc-demo-ig-www --zone=us-west2-a
gcloud compute instance-groups unmanaged add-instances vpc-demo-ig-www --zone=us-west2-a
gcloud compute health-checks create http hc-http-80 --port=80

# Create TCP backend services, forwarding rule & firewall
gcloud compute backend-services create vpc-demo-www-be-tcp \
  --load-balancing-scheme=internal --protocol=tcp \
  --region=us-west2 --health-checks=hc-http-80

gcloud compute backend-services add-backend vpc-demo-www-be-tcp \
  --region=us-west2 --instance-group=vpc-demo-ig-www \
  --instance-group-zone=us-west2-a

gcloud compute forwarding-rules create vpc-demo-www-ilb-tcp \
  --region=us-west2 --load-balancing-scheme=internal \
  --network=vpc-demo-producer --subnet=vpc-demo-us-west2 \
  --address=10.0.2.10 --ip-protocol=TCP --ports=all \
  --backend-service=vpc-demo-www-be-tcp \
  --backend-service-region=us-west2

gcloud compute firewall-rules create vpc-demo-health-checks \
  --allow tcp:80,tcp:443 --network=vpc-demo-producer \
  --source-ranges 130.211.0.0/22,35.191.0.0/16 --enable-logging

gcloud compute firewall-rules create psclab-iap-prod \
  --allow tcp:22 --network=vpc-demo-producer \
  --source-ranges=35.235.240.0/20 --enable-logging

# Create TCP NAT subnet
gcloud compute networks subnets create vpc-demo-us-west2-psc-tcp \
  --network=vpc-demo-producer --region=us-west2 \
  --range=192.168.0.0/24 --purpose=private-service-connect

# Create TCP service attachment and firewall rules
gcloud compute service-attachments create vpc-demo-psc-west2-tcp \
  --region=us-west2 --producer-forwarding-rule=vpc-demo-www-ilb-tcp \
  --connection-preference=ACCEPT_AUTOMATIC --nat-subnets=vpc-demo-us-west2-psc-tcp

gcloud compute service-attachments describe vpc-demo-psc-west2-tcp --region=us-west2
gcloud compute firewall-rules create vpc-demo-allowpsc-tcp \
  --project=$PROD_PROJ --direction=INGRESS --priority=1000 \
  --network=vpc-demo-producer --action=ALLOW \
  --rules=all --source-ranges=192.168.0.0/24 --enable-logging

# Create Consumers VPC network
gcloud config list project
gcloud config set project $CONSUMER_PROJ
gcloud compute networks create vpc-demo-consumer \
  --project=$CONSUMER_PROJ --subnet-mode=custom

gcloud compute networks subnets create consumer-subnet \
  --project=$CONSUMER_PROJ --range=10.0.60.0/24 \
  --network=vpc-demo-consumer --region=us-west2

gcloud compute addresses create vpc-consumer-psc-tcp \
  --region=us-west2 --subnet=consumer-subnet --addresses=10.0.60.100

gcloud compute firewall-rules create psclab-iap-consumer \
  --network=vpc-demo-consumer --allow tcp:22 \
  --source-ranges=35.235.240.0/20 --enable-logging

gcloud compute firewall-rules create vpc-consumer-psc --project=$CONSUMER_PROJ \
  --direction=EGRESS --priority=1000 --network=vpc-demo-consumer \
  --action=ALLOW --rules=all --destination-ranges=10.0.60.0/24 --enable-logging

# Create Cloud NAT instance
gcloud compute routers create crnatconsumer --network=vpc-demo-consumer --region us-west2
gcloud compute routers nats create cloudnatconsumer \
  --router=crnatconsumer --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges --enable-logging --region=us-west2
