#Create instance apache https
gcloud compute instances create www \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone us-central1-b \
    --tags https-tag \
    --metadata startup-script="#! /bin/bash
      sudo apt-get update
      sudo apt-get install apache2 -y
      sudo a2ensite default-ssl
      sudo a2enmod ssl
      sudo service apache2 restart
      echo '<!doctype html><html><body><h1>www</h1></body></html>' | sudo tee /var/www/html/index.html
      EOF"
      
      gcloud compute instances create www-video \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone us-central1-b \
    --tags https-tag \
    --metadata startup-script="#! /bin/bash
      sudo apt-get update
      sudo apt-get install apache2 -y
      sudo a2ensite default-ssl
      sudo a2enmod ssl
      sudo service apache2 restart
      echo '<!doctype html><html><body><h1>www-video</h1></body></html>' | sudo tee /var/www/html/index.html
      sudo mkdir /var/www/html/video
      echo '<!doctype html><html><body><h1>www-video</h1></body></html>' | sudo tee /var/www/html/video/index.html
      EOF"
gcloud compute firewall-rules create www-firewall -target-tags https-tag --allow tcp:443
gcloud compute instances list
#Create IPv4 and IPv6 global static external IP addresses for load balancer.
gcloud compute addresses create lb-ip-1 --ip-version=IPV4 --global
gcloud compute addresses create lb-ipv6-1 --ip-version=IPV6 --global
#Create an instance group for each traffic type
gcloud compute instance-groups unmanaged create video-resources --zone us-central1-b
gcloud compute instance-groups unmanaged create www-resources --zone us-central1-b
#Add the instances
gcloud compute instance-groups unmanaged add-instances video-resources \
    --instances www-video \
    --zone us-central1-b
gcloud compute instance-groups unmanaged add-instances www-resources \
    --instances www \
    --zone us-central1-b
#For each instance group, define an HTTPS service and map a port name to the relevant port
gcloud compute instance-groups unmanaged set-named-ports video-resources \
    --named-ports https:443 \
    --zone us-central1-b
gcloud compute instance-groups unmanaged set-named-ports www-resources \
    --named-ports https:443 \
    --zone us-central1-b
gcloud compute health-checks create https https-basic-check --port 443
#Create a backend service for each content provider
gcloud compute backend-services create video-service \
    --protocol HTTPS \
    --health-checks https-basic-check \
    --global
gcloud compute backend-services create web-map-backend-service \
    --protocol HTTPS \
    --health-checks https-basic-check \
    --global
#A backend defines the capacity (max CPU utilization or max queries per second) of the instance groups it contains.
gcloud compute backend-services add-backend video-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group video-resources \
    --instance-group-zone us-central1-b \
    --global
    
gcloud compute backend-services add-backend web-map-backend-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group www-resources \
    --instance-group-zone us-central1-b \
    --global
#Create a URL map  
gcloud compute url-maps create web-map --default-service web-map-backend-service
gcloud compute url-maps add-path-matcher web-map \
   --default-service web-map-backend-service --path-matcher-name pathmap \
   --path-rules=/video=video-service,/video/*=video-service
#Create ssl_cert
mkdir ssl_cert
cd ssl_cert
openssl genrsa -out example.key 2048
openssl req -new -key example.key -out example.csr
#To create a self-managed SSL certificate resource
gcloud compute ssl-certificates create www-ssl-cert --certificate ./example.crt --private-key ./example.key
#Optionally, create an SSL policy for the load balancer
gcloud compute ssl-policies create cb-ssl-policy --profile MODERN --min-tls-version 1.0
#Create a target HTTPS proxy to route requests to your URL map.
gcloud compute target-https-proxies create https-lb-proxy --url-map web-map --ssl-certificates www-ssl-cert
gcloud compute addresses list
#Optionally, enable the QUIC protocol
gcloud compute target-https-proxies update https-lb-proxy --quic-override=ENABLE
#Create two global forwarding rules to route incoming requests to the proxy, 
gcloud compute forwarding-rules create https-content-rule \
    --address LB_IP_ADDRESS$ \
    --global \
    --target-https-proxy https-lb-proxy \
    --ports 443
    
gcloud compute forwarding-rules create https-content-ipv6-rule \
    --address $LB_IPV6_ADDRESS \
    --global \
    --target-https-proxy https-lb-proxy \
    --ports 443

gcloud compute forwarding-rules list
#Since traffic between the proxies and instances is over IPv4
gcloud compute firewall-rules create allow-lb-and-healthcheck \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --target-tags https-tag \
    --allow tcp:443
#remove the rule that allows HTTP(S) traffic from other sources
gcloud compute firewall-rules delete www-firewall
#Removing external IP addresses except for a bastion host
gcloud compute instances list
#Delete the access config for the instance. For NAME, put the name of the instance
gcloud compute instances delete-access-config NAME
