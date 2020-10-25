#Create a few Nginx instances using a Bitnami Nginx Stack image, which includes a complete PHP, MySQL and Nginx development environment
for i in {1..3}; \
do \
  gcloud compute instances create "nginxstack-$i" \
  --machine-type "f1-micro" \
  --tags nginxstack-tcp-443,nginxstack-tcp-80 \
  --zone us-central1-f \
  --image   "https://www.googleapis.com/compute/v1/projects/bitnami-launchpad/global/images/bitnami-nginx-1-16-0-0-r50-linux-debian-9-x86-64" \
  --boot-disk-size "200" --boot-disk-type "pd-standard" \
  --boot-disk-device-name "nginxstack-$i"; \
done
#create a firewall rule
gcloud compute firewall-rules create nginx-firewall \
 --allow tcp:80,tcp:443 \
 --target-tags nginxstack-tcp-80,nginxstack-tcp-443
 
