#!/bin/bash
apt-get update
apt-get install tcpdump -y
apt-get install apache2 -y
a2ensite default-ssl
apt-get install iperf3 -y
a2enmod ssl
VM_HOSTNAME="$(curl -H "Metadata-Flavor:Google" \
  http://169.254.169.254/computeMetadata/v1/instance/name)"
FILTER="{print \$NF}"
VM_ZONE="$(curl -H "Metadata-Flavor:Google" \
  http://169.254.169.254/computeMetadata/v1/instance/zone \
  | awk -F/ "${FILTER}")"
echo "Page on $VM_HOSTNAME in $VM_ZONE" | tee /var/www/html/index.html
systemctl restart apache2
iperf3 -s -p 5050
