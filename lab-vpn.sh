#Create networks
gcloud compute --project=qwiklabs-gcp-54b8c874b0f06192 networks create vpn-network-2 --description="europe-west vpn-network-2" --subnet-mode=custom
gcloud compute --project=qwiklabs-gcp-54b8c874b0f06192 networks subnets create subnet-b --network=vpn-network-2 --region=europe-west1 --range=10.1.3.0/24
#Create the utility VMs
gcloud beta compute --project=qwiklabs-gcp-54b8c874b0f06192 instances create server-1 --zone=us-central1-b --machine-type=f1-micro --subnet=subnet-a --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=435705017535-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=debian-9-stretch-v20190813 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=server-1 --reservation-affinity=any
gcloud beta compute --project=qwiklabs-gcp-54b8c874b0f06192 instances create server-2 --zone=europe-west1-b --machine-type=f1-micro --subnet=subnet-b --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=435705017535-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=debian-9-stretch-v20190813 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=server-2 --reservation-affinity=any
#Create the firewall rules
gcloud compute --project=qwiklabs-gcp-54b8c874b0f06192 firewall-rules create allow-icmp-ssh-network-1 --direction=INGRESS --priority=1000 --network=vpn-network-1 --action=ALLOW --rules=tcp:22,icmp --source-ranges=0.0.0.0/0
gcloud compute --project=qwiklabs-gcp-54b8c874b0f06192 firewall-rules create allow-icmp-ssh-network-2 --direction=INGRESS --priority=1000 --network=vpn-network-2 --action=ALLOW --rules=tcp:22,icmp --source-ranges=0.0.0.0/0
#Set up the VPN for both networks
gcloud compute target-vpn-gateways \
create vpn-1 \
--network vpn-network-1  \
--region us-central1

gcloud compute target-vpn-gateways \
create vpn-2 \
--network vpn-network-2  \
--region europe-west1
#Reserve a static IP for each network
gcloud compute addresses create --region us-central1 vpn-1-static-ip
gcloud compute addresses list
export STATIC_IP_VPN_1=<Enter IP address for vpn-1 here>

gcloud compute addresses create --region europe-west1 vpn-2-static-ip
gcloud compute addresses list
export STATIC_IP_VPN_2=<Enter IP address for vpn-2 here>
#Create forwarding rules for both vpn gateways
gcloud compute \
forwarding-rules create vpn-1-esp \
--region us-central1  \
--ip-protocol ESP  \
--address $STATIC_IP_VPN_1 \
--target-vpn-gateway vpn-1

gcloud compute \
forwarding-rules create vpn-2-esp \
--region europe-west1  \
--ip-protocol ESP  \
--address $STATIC_IP_VPN_2 \
--target-vpn-gateway vpn-2

gcloud compute \
forwarding-rules create vpn-1-udp500  \
--region us-central1 \
--ip-protocol UDP \
--ports 500 \
--address $STATIC_IP_VPN_1 \
--target-vpn-gateway vpn-1

gcloud compute \
forwarding-rules create vpn-2-udp500  \
--region europe-west1 \
--ip-protocol UDP \
--ports 500 \
--address $STATIC_IP_VPN_2 \
--target-vpn-gateway vpn-2

gcloud compute \
forwarding-rules create vpn-1-udp4500  \
--region us-central1 \
--ip-protocol UDP --ports 4500 \
--address $STATIC_IP_VPN_1 \
--target-vpn-gateway vpn-1

gcloud compute \
forwarding-rules create vpn-2-udp4500  \
--region europe-west1 \
--ip-protocol UDP --ports 4500 \
--address $STATIC_IP_VPN_2 \
--target-vpn-gateway vpn-2

gcloud compute target-vpn-gateways list
#Create tunnels
gcloud compute \
vpn-tunnels create tunnel1to2  \
--peer-address $STATIC_IP_VPN_2 \
--region us-central1 \
--ike-version 2 \
--shared-secret gcprocks \
--target-vpn-gateway vpn-1 \
--local-traffic-selector 0.0.0.0/0 \
--remote-traffic-selector 0.0.0.0/0

gcloud compute \
vpn-tunnels create tunnel2to1 \
--peer-address $STATIC_IP_VPN_1 \
--region europe-west1 \
--ike-version 2 \
--shared-secret gcprocks \
--target-vpn-gateway vpn-2 \
--local-traffic-selector 0.0.0.0/0 \
--remote-traffic-selector 0.0.0.0/0

gcloud compute vpn-tunnels list
#Create static routes
gcloud compute  \
routes create route1to2  \
--network vpn-network-1 \
--next-hop-vpn-tunnel tunnel1to2 \
--next-hop-vpn-tunnel-region us-central1 \
--destination-range 10.1.3.0/24

gcloud compute  \
routes create route2to1  \
--network vpn-network-2 \
--next-hop-vpn-tunnel tunnel2to1 \
--next-hop-vpn-tunnel-region europe-west1 \
--destination-range 10.5.4.0/24
