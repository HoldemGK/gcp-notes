#!/bin/bash
set -x
# Setup console and startup-script logging
LOG_FILE=/var/log/minecraft/startup_script.log
mkdir -p  /var/log/minecraft /var/cloud/config
[[ -f $LOG_FILE ]] || /usr/bin/touch $LOG_FILE
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1

# Create runtime configuration on first boot
echo "Creating first_start.sh"
echo ${NETDATA_TOKEN} #TODO clear
cat << 'EOF' > /etc/init.d/first_start.sh
#!/bin/bash
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-minecraft-disk
sudo mount -o discard,defaults /dev/disk/by-id/google-minecraft-disk /home/minecraft
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk default-jre-headless wget

# Monitoring
echo "NETDATA_TOKEN ${NETDATA_TOKEN}" #TODO clear
wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --claim-token ${NETDATA_TOKEN} --claim-url https://app.netdata.cloud --non-interactive

# Backup prepare
{ crontab -l; echo '0 */4 * * * /etc/init.d/backup.sh'; } | crontab -
      
cd /home/minecraft
sudo wget https://piston-data.mojang.com/v1/objects/c9df48efed58511cdd0213c56b9013a7b5c9ac1f/server.jar
sudo java -Xmx1024M -Xms1024M -jar server.jar nogui
sed -i "s/eula=false/eula=true/g" ./eula.txt
sudo apt-get install -y screen
touch /var/cloud/config/startup_finished
sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui &
EOF

# Create backup script on first boot
echo "Creating backup.sh"
cat << 'EOF' > /etc/init.d/backup.sh
#!/bin/bash
now=$(date +'%Y%m%d%H%M%S')
screen -r mcs -X stuff '/save-all\n/save-off\n'
gsutil -m cp -R $${BASH_SOURCE%/*}/world gs://${BUCKET_PREFIX}-minecraft-backup/$(date "+%Y%m%d-%H%M%S")-world
screen -r mcs -X stuff '/save-on\n'
echo "saved file at $now"
EOF

# skip startup script if already complete
if [[ -f /var/cloud/config/startup_finished ]]; then
  echo "Every time starting!"
  crontab -l
  mount /dev/disk/by-id/google-minecraft-disk /home/minecraft
  cd /home/minecraft
  sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui
  echo "Onboarding complete, skip startup script"
  exit
  
else  # Run first boot scripts
  echo "Running first boot scripts"
  sudo chmod +x /etc/init.d/first_start.sh /etc/init.d/backup.sh
  bash /etc/init.d/first_start.sh
  #crontab -l | { cat; echo "0 */4 * * * /home/minecraft/backup.sh"; } | crontab -
fi