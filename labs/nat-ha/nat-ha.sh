# Building High Availability and High Bandwidth NAT Gateways

gcloud compute networks create example-vpc --subnet-mode custom
gcloud compute networks subnets create example-east \
  --network example-vpc --range 10.0.1.0/24 --region us-east1

gcloud compute instances create bastion-host \
  --network example-vpc \
  --subnet example-east \
  --zone us-east1-b \
  --image-family debian-9 \
  --image-project debian-cloud

gcloud compute instances create isolated-host \
  --network example-vpc \
  --subnet example-east \
  --no-address \
  --zone us-east1-b \
  --image-family debian-9 \
  --image-project debian-cloud \
  --tags no-ip

gcloud compute firewall-rules create allow-example-ssh \
  --allow tcp:22 \
  --source-ranges 0.0.0.0/0 \
  --network example-vpc

gcloud compute firewall-rules create allow-example-instal \
  --allow tcp:1-65535,udp:1-65535,icmp \
  --source-ranges 10.0.1.0/24 \
  --network example-vpc

# Reserve and store three static IP addresses for NAT nodes
for i in {1..3}; do \
gcloud compute addresses create nat-$i --region us-east1
nat_$i_ip=$(gcloud compute addresses describe nat-$i \
  --region us-east1 \
  --format='value(address)')

gcloud compute instance-templates create nat-$i \
  --machine-type n1-standard-2 \
  --can-ip-forward \
  --tags natgw \
  --metadata-from-file=startup-script=startup.sh \
  --address $nat_$i_ip \
  --network example-vpc \
  --subnet example-east \
  --region us-east1;
done

gcloud compute instance-templates list

# Create a health check to monitor responsiveness
gcloud compute health-checks create http nat-health-check \
  --check-internal 30 \
  --healthy-threshold 1 \
  --unhealthy-threshold 5 \
  --request-path /health-check

gcloud compute firewall-rules create "natfirewall" \
  --allow tcp:80 \
  --target-tags natgw \
  --source-ranges "209.85.152.0/22","209.85.204.0/22","35.191.0.0/16"

# Create an instance group for each NAT gateway
gcloud compute instance-groups managed create nat-1 \
  --size=1 \
  --template=nat-2 \
  --zone=us-east1-b

gcloud compute instance-groups managed create nat-2 \
  --size=1 \
  --template=nat-2 \
  --zone=us-east1-c

gcloud compute instance-groups managed create nat-3 \
  --size=1 \
  --template=nat-3 \
  --zone=us-east1-d

gcloud compute instance-groups list

# Set up autohealing to restart unresponsive NAT gateways
gcloud beta compute instance-groups managed set-autohealing nat-1 \
  --health-check nat-health-check \
  --initial-delay 120 \
  --zone us-east1-b

gcloud beta compute instance-groups managed set-autoscaling nat-2 \
  --health-check nat-health-check \
  --initial-delay 120 \
  --zone us-east1-c

gcloud beta compute instance-groups managed set-autoscaling nat-3 \
  --health-check nat-health-check \
  --initial-delay 120 \
  --zone us-east1-d

nat_1_instance=$(gcloud compute instances list | awk '$1 ~ /^nat-1/ { print $1 }')
nat_2_instance=$(gcloud compute instances list | awk '$1 ~ /^nat-2/ { print $1 }')
nat_3_instance=$(gcloud compute instances list | awk '$1 ~ /^nat-3/ { print $1 }')

# Add default routes to your instances
gcloud compute routes create natroute1 \
  --network example-vpc \
  --destination-range 0.0.0.0/0 \
  --tags no-ip \
  --priority 800 \
  --next-hop-instance-zone us-east1-b \
  --next-hop-instance $nat_1_instance

gcloud compute routes create natroute2 \
  --network example-vpc \
  --destination-range 0.0.0.0/0 \
  --tags no-ip \
  --priority 800 \
  --next-hop-instance-zone us-east1-c \
  --next-hop-instance $nat_2_instance

gcloud compute routes create natroute3 \
  --network example-vpc \
  --destination-range 0.0.0.0/0 \
  --tags no-ip \
  --priority 800 \
  --next-hop-instance-zone us-east1-d \
  --next-hop-instance $nat_3_instance
