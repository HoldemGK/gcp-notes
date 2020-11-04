# Migrating a MySQL Cluster to Compute Engine Using HAProxy

export PROJECT=${DEVSHELL_PROJECT_ID}
export ZONE=us-central1-c
export GCS_BUCKET_NAME=${USER}-mysql-$(date +%s)
gsutil mb gs://${GCS_BUCKET_NAME}
git clone https://github.com/GoogleCloudPlatform/solutions-compute-mysql-migration-haproxy.git mysql-migration
cd mysql-migration
./run.sh ${DEVSHELL_PROJECT_ID} ${GCS_BUCKET_NAME}

# set up the source-mysql-replica instance to replicate the data to other instances
mysql -u root -psolution-admin -e "GRANT REPLICATION SLAVE ON *.* TO 'sourcereplicator'@'%' IDENTIFIED BY 'solution-admin';"
sudo bash -c 'echo log_slave_updates = 1 >>/etc/mysql/mysql.conf.d/mysqld.cnf'
sudo service mysql restart

# Setting up the service account for target MySQL instances
gcloud iam service-accounts create mysql-instance \
  --display-name "mysql-instance"

gcloud projects add-iam-policy-binding ${PROJECT} \
  --member=serviceAccount:mysql-instance@${PROJECT}.iam.gserviceaccount.com \
  --role=roles/storage.objectAdmin

# Setting up the target MySQL instance on Compute Engine
gcloud compute instances create target-mysql-primary \
  --image-family=ubuntu-1604-lts --image-project=ubuntu-os-cloud \
  --tags=mysql57 --zone=$ZONE \
  --service-account=mysql-instance@${PROJECT}.iam.gserviceaccount.com \
  --scopes=https://www.googleapis.com/auth/devstorage.read_write

gcloud compute firewall-rules create mysql --allow=tcp:3306 \
  --source-tags source-mysql --target-tags target-mysql

# Setting up secured root access between the source replica and target primary instances
gcloud compute ssh target-mysql-primary
sudo apt-get update
sudo apt-get -y install mysql-server-5.7
sudo ssh-keygen
sudo bash -c "gsutil cp /root/.ssh/id_rsa.pub gs://${GCS_BUCKET_NAME}/"
exit

gcloud compute ssh target-mysql-replica
sudo bash -c "gsutil cp gs://${GCS_BUCKET_NAME}/id_rsa.pub /root/.ssh/target-mysql-primary.pub"
sudo bash -c "cat /root/.ssh/target-mysql-primary.pub >> /root/.ssh/authorized_keys"
exit

# Copy the MySQL data files from the source-mysql-replica instance to the target-mysql-primary
gcloud compute ssh target-mysql-primary
sudo service mysql stop
# Delete the contents of /var/lib/mysql
sudo bash -c "rm -rf /var/lib/mysql/*"
# Copy the database files from the source
sudo bash -c "rsync -av source-mysql-replica:/var/lib/mysql/ /var/lib/mysql"
exit

# Pause the replication
gcloud compute ssh target-mysql-replica
mysql -uroot -psolution-admin -e 'show master status; stop slave;'
exit

# On the target-mysql-primary instance, run the following command to ensure that the target-mysql-primary instance is consistent with the source-mysql-replica instance, because you didn't stop the writes during the first copy operation
gcloud compute ssh target-mysql-primary
sudo bash -c "rsync -av source-mysql-replica:/var/lib/mysql/ /var/lib/mysql"
exit

# On the source-mysql-replica instance, resume the replication
gcloud compute ssh target-mysql-replica
sudo mysql -uroot -psolution-admin -e 'start slave;'
exit

# Remove the file containing the default MySQL instance ID from target-mysql-primary
gcloud compute ssh target-mysql-primary
sudo rm /var/libmysql/auto.cnf
# Update the MySQL configuration to replicate the source_db database from the source-mysql-replica instance
sudo sed -i "s|#server-id.*|server-id = 4|" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i "s|#log_bin|log_bin|" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i "s|#binlog_do_db.*|binlog_do_db = source_db|" /etc/mysql/mysql.conf.d/mysqld.cnf
# Enable MySQL to accept connections from other hosts on its network
LOCAL_IP=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip \
  -H "Metadata-Flavor: Google")
sudo sed -i "s|bind-address.*|bind-address = $LOCAL_IP|" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo service mysql start
# Log in to the MySQL console and Reset the primary instance
mysql -u root -p solution-admin
reset slave;
# Configure the replication process
CHANGE MASTER TO MASTER_HOST='source-mysql-replica', \
  MASTER_USER='sourcereplicator', MASTER_PASSWORD='solution-admin', \
  MASTER_LOG_FILE='mysql-bin.000002', MASTER_LOG_POS=154;

start slave;
SELECT * FROM source_db.source_table;
show slave status \G
exit

# Creating the HAProxy instance
gcloud compute instances create haproxy --image-family=ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud --tags=haproxy,http-server \
  --zone=$ZONE --private-network-ip=10.128.0.100

gcloud compute ssh haproxy
sudo apt-get update
sudo apt-get install -y haproxy=1.6.3-1
sudo apt-get install -y mysql-client
exit

gcloud compute firewall-rules create haproxy-mysql --allow=tcp:3306 \
  --source-tags haproxy --target-tags target-mysql,source-mysql

gcloud compute firewall-rules create haproxy-admin --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 --target-tags haproxy

# Set up HAProxy authentication for the target-mysql-primary instance
gcloud compute ssh target-mysql-primary
# Create user haproxy_check and haproxy_root
mysql -uroot -psolution-admin -e "INSERT INTO mysql.user \
  (Host,User,ssl_cipher,x509_issuer,x509_subject) values \
  ('10.128.0.100','haproxy_check','','',''); FLUSH PRIVILEGES";

PROJECT=`curl \
http://metadata.google.internal/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google"`
HA_PROXY_FQDN=haproxy.c.$PROJECT.internal
mysql -uroot -psolution-admin -e "GRANT ALL PRIVILEGES ON *.* TO \
  'haproxy_root'@'"$HA_PROXY_FQDN"' IDENTIFIED BY 'solution-admin' WITH \
  GRANT OPTION; FLUSH PRIVILEGES;"
exit

# Set up HAProxy authentication for the source-mysql-primary instance
gcloud compute ssh source-mysql-primary
mysql -uroot -psolution-admin -e "INSERT INTO mysql.user \
  (Host,User,ssl_cipher,x509_issuer,x509_subject) values \
  ('10.128.0.100','haproxy_check','','',''); FLUSH PRIVILEGES;"

PROJECT=`curl \
http://metadata.google.internal/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google"`
HA_PROXY_FQDN=haproxy.c.$PROJECT.internal
mysql -uroot -psolution-admin -e "GRANT ALL PRIVILEGES ON *.* TO \
  'haproxy_root'@'"$HA_PROXY_FQDN"' IDENTIFIED BY 'solution-admin' WITH \
  GRANT OPTION; FLUSH PRIVILEGES;"
exit

# Test connectivity between HAProxy and the MySQL primary instances
gcloud compute ssh haproxy
mysql -h source-mysql-primary -u haproxy_root -psolution-admin -e "SHOW DATABASES"
mysql -h target-mysql-primary -u haproxy_root -psolution-admin -e "SHOW DATABASES"

# Create the HAProxy configuration file and point it to the source-mysql-primary instance
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bkp
