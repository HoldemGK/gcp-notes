export REGION="us-west1"
gcloud config set project $PROJECT
gcloud compute networks create hybrid-network-lb --subnet-mode custom
gcloud compute networks subnets create network-endpoint-group-subnet --network hybrid-network-lb

# Create Cloud NAT instance
gcloud compute routers create crnat --network hybrid-network-lb --region $REGION
gcloud compute routers nats create cloudnat --router=crnat --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges --enable-logging --region=$REGION

# Create two VM instances
gcloud compute instances create on-prem-neg-1 \
  --zone=${REGION}-a \
  --tags=allow-health-check \
  --image-family=debian-9 \
  --image-project=debian-cloud \
  --subnet=network-endpoint-group-subnet --no-address \
  --metadata-from-file=startup-script=start-script.sh
gcloud compute instances create on-prem-neg-2 \
  --zone=${REGION}-a \
  --tags=allow-health-check \
  --image-family=debian-9 \
  --image-project=debian-cloud \
  --subnet=network-endpoint-group-subnet --no-address \
  --metadata-from-file=startup-script=start-script.sh

# Create a NEG containing you on-premise endpoint
gcloud compute network-endpoint-groups create on-prem-neg-1 \
  --network-endpoint-type NON_GCP_PRIVATE_IP_PORT \
  --zone ${REGION}-a \
  --network hybrid-network-lb
gcloud compute network-endpoint-groups create on-prem-neg-2 \
  --network-endpoint-type NON_GCP_PRIVATE_IP_PORT \
  --zone ${REGION}-a \
  --network hybrid-network-lb

IP_1="$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances list | grep -i on-prem-1)"
IP_2="$(gcloud --format="value(networkInterfaces[0].networkIP)" compute instances list | grep -i on-prem-2)"

gcloud compute network-endpoint-groups update on-prem-neg-1 \
  --zone="${REGION}-a" \
  --add-endpoint="${IP_1},port=80"
gcloud compute network-endpoint-groups update on-prem-neg-2 \
  --zone="${REGION}-a" \
  --add-endpoint="${IP_2},port=80"

# Create the http health-check, backend service & firewall
gcloud compute health-checks create http on-prem-health-check
gcloud compute backend-service create on-prem-backend-service \
  --global \
  --load-balancing-scheme=EXTERNAL \
  --health-checks on-prem-health-check

gcloud compute firewall-rules create fw-allow-health-check \
  --network=hybrid-network-lb \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

# Associate the NEG and backend service
gcloud compute backend-services add-backend on-prem-backend-service \
  --global \
  --network-endpoint-group on-prem-neg-1 \
  --network-endpoint-group-zone ${REGION}-a \
  --balancing-mode RATE \
  --max-rate-per-endpoint 5

gcloud compute backend-services add-backend on-prem-backend-service \
  --global \
  --network-endpoint-group on-prem-neg-2 \
  --network-endpoint-group-zone ${REGION}-a \
  --balancing-mode RATE \
  --max-rate-per-endpoint 5

gcloud compute addresses create hybrid-lb-ip --project=$PROJECT --global
