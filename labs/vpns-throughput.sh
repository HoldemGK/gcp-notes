# building-high-throughput-vpns
# Creating the cloud VPC
gcloud compute networks create cloud --subnet-mode custom
gcloud compute firewall-rules create cloud-fw --network cloud --allow tcp:22,icmp
gcloud compute networks subnets create cloud-east --network cloud \
  --range 10.0.1.0/24 --region us-east1

# Creating the on-prem VPC
gcloud compute networks create on-prem --subnet-mode custom
gcloud compute firewall-rules create on-prem-fw --network on-prem --allow tcp:22,icmp
gcloud compute networks subnets create on-prem-central --network on-prem \
  --range 192.168.1.0/24 --region us-central1

# Creating VPN gateways
gcloud compute target-vpn-gateways create on-prem-gw1 --network on-prem --region us-central1
gcloud compute target-vpn-gateways create cloud-gw1 --network cloud --region us-east1
# Creating a route-based VPN tunnel between local and Google Cloud networks
gcloud compute addresses create cloud-gw1 --region us-east1
gcloud compute addresses create on-prem-gw1 --region us-central1
export cloud_gw1_ip=$(gcloud compute addresses describe cloud-gw1 \
  --region us-east1 --format='value(address)')

export on_prem_gw_ip=$(gcloud compute addresses describe on-prem-gw1 \
  --region us-central1 --format='value(address)')
# Create forwarding rules for IPsec on the cloud VPC
gcloud compute forwarding-rules create cloud-1-fr-esp --ip-protocol ESP \
  --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region us-east1

gcloud compute forwarding-rules create cloud-1-fr-udp500 --ip-protocol UDP \
  --ports 500 --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region us-east1

gcloud compute forwarding-rules create cloud-fr-1-udp4500 --ip-protocol UDP \
  --ports 4500 --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region us-east1

# Create forwarding rules for IPsec on the on-prem VPC
gcloud compute forwarding-rules create on-prem-fr-esp --ip-protocol ESP \
  --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region us-central1

gcloud compute forwarding-rules create on-prem-fr-udp500 --ip-protocol UDP \
  --ports 500 --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region us-central1

gcloud compute forwarding-rules create on-prem-fr-udp4500 --ip-protocol UDP \
  --ports 4500 --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region us-central1

gcloud secrets create vpn_secret --replication-policy="automatic"

# Create the VPN tunnel from on-prem to cloud
gcloud compute vpn-tunnels create on-prem-tunnel1 --peer-address $cloud_gw1_ip \
  --target-vpn-gateway on-prem-gw1 --ike-version 2 --local-traffic-selector 0.0.0.0/0 \
  --remote-traffic-selector 0.0.0.0/0 --shared-secret=vpn_secret --region us-central1

# Create the VPN tunnel from cloud to on-prem
gcloud compute vpn-tunnels create cloud-tunnel1 --peer-address $on_prem_gw_ip \
  --target-vpn-gateway cloud-gw1 --ike-version 2 --local-traffic-selector 0.0.0.0/0 \
  --remote-traffic-selector 0.0.0.0/0 --shared-secret=vpn_secret --region us-east1

# Route traffic from the on-prem VPC to the cloud
gcloud compute routes create on-prem-route1 --destination-range 10.0.1.0/24 \
  --network on-prem --next-hop-vpn-tunnel on-prem-tunnel1 \
  --next-hop-vpn-tunnel-region us-central1

# Route traffic from the cloud VPC to the on-prem
gcloud compute routes create cloud-route1 --destination-range 192.168.1.0/24 \
  --network cloud --next-hop-vpn-tunnel cloud-tunnel1 \
  --next-hop-vpn-tunnel-region us-east1

# Testing throughput over VPN
gcloud compute instances create "cloud-loadtest" --zone "us-east1-b" \
  --machine-type "n1-standard-4" --subnet "cloud-east" \
  --image-family "debian-9" --image-project "debian-cloud" \
  --boot-disk-size "10" --boot-disk-type "pd-standard" --boot-disk-device-name "cloud-loadtest"

gcloud compute instances create "on-prem-loadtest" --zone "us-central1-a" \
  --machine-type "n1-standard-4" --subnet "on-prem-central" \
  --image-family "debian-9" --image-project "debian-cloud" \
  --boot-disk-size "10" --boot-disk-type "pd-standard" --boot-disk-device-name "on-prem-loadtest"

gcloud compute firewall-rules create on-prem-iperf-fw --network on-prem --allow tcp:5001
# connect to each VM and install a copy of iperf
sudo apt-get install iperf
iperf -s -i 5 -p 5001
# On the cloud-loadtest VM
iperf -c 192.168.1.2 -P 20 -x C -p 5001

# Multiple VPN load testing. Create an additional cloud VPN gateway,cloud-gw2
gcloud compute target-vpn-gateway create cloud-gw2 --network cloud --region us-east1
gcloud compute addresses create aloud-gw2 --region us-east1
export cloud_gw2_ip=$(gcloud compute addresses describe cloud-gw2 \
  --region us-east1 --format='value(address)')

# Create forwarding rules on cloud-gw2
gcloud compute forwarding-rules create cloud-2-fr-esp --ip-protocol ESP \
  --address $cloud_gw2_ip --target-vpn-gateway cloud-gw2 --region us-east1

gcloud compute forwarding-rules create cloud-2-fr-udp500 --ip-protocol UDP \
  --ports 500 --address $cloud_gw2_ip --target-vpn-gateway cloud-gw2 --region us-east1

gcloud compute forwarding-rules create cloud-fr-2-udp4500 --ip-protocol UDP \
  --ports 4500 --address $cloud_gw2_ip --target-vpn-gateway cloud-gw2 --region us-east1

# Tunnel from on-prem to cloud-gw2
gcloud compute vpn-tunnels create on-prem-tunnel2 --peer-address $cloud_gw2_ip \
  --target-vpn-gateway on-prem-gw1 --ike-version 2 --local-traffic-selector 0.0.0.0/0 \
  --remote-traffic-selector 0.0.0.0/0 --shared-secret=vpn-secret --region us-central1

# Tunnel from cloud-gw2 to on-prem
gcloud compute vpn-tunnels create cloud-tunnel2 --peer-address $on_prem_gw_ip \
  --target-vpn-gateway cloud-gw2 --ike-version 2 --local-traffic-selector 0.0.0.0/0 \
  --remote-traffic-selector 0.0.0.0/0 --shared-secret=vpn-secret --region us-east1

# Route from on-prem to cloud-gw2
gcloud compute routes create on-prem-route2 --destination-range 10.0.1.0/24 --network on-prem \
  --next-hop-vpn-tunnel on-prem-tunnel2 --next-hop-vpn-tunnel-region us-central1

# Route from cloud-gw2 to on-prem
gcloud compute routes create cloud-route2 --destination-range 192.168.1.0/24 --network cloud\
  --next-hop-vpn-tunnel cloud-tunnel2 --next-hop-vpn-tunnel-region us-east1

# Use iperf to retest the speed of the networ
iperf -c 192.168.1.2 -P 20 -x C
