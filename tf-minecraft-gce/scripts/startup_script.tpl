#!/bin/bash
set -x
# Setup console and startup-script logging
LOG_FILE=/var/log/minecraft/startup_script.log
SCRIPT_PATH=/etc/init.d
CL_CO_PATH=/var/cloud/config
MC_PATH=/home/minecraft

mkdir -p  /var/log/minecraft $MC_PATH $CL_CO_PATH
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
cat << 'EOF' > $SCRIPT_PATH/first_start.sh
#!/bin/bash

sudo apt-get update
sudo apt-get install -y openjdk-17-jdk default-jre-headless wget
echo "Installing packages completed"
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-minecraft-disk
sudo mount -o discard,defaults /dev/disk/by-id/google-minecraft-disk /home/minecraft

# Monitoring
wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --claim-token ${NETDATA_TOKEN} --claim-url https://app.netdata.cloud --non-interactive

# Backup prepare
{ crontab -l; echo '0 */4 * * * /etc/init.d/backup.sh'; } | crontab -
      
cd /home/minecraft
pwd
sudo wget https://piston-data.mojang.com/v1/objects/c9df48efed58511cdd0213c56b9013a7b5c9ac1f/server.jar
echo "Initialising server settings... "
java -jar server.jar --initSettings >/dev/null
sed -i "s/eula=false/eula=true/g" eula.txt
echo "eula=false->true"
echo "Installing screen... "
sudo apt-get install -y screen
touch /var/cloud/config/startup_finished
sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui &
EOF

# Create backup script on first boot
echo "Creating backup.sh"
cat << 'EOF' > $SCRIPT_PATH/backup.sh
#!/bin/bash
now=$(date +'%Y%m%d%H%M%S')
screen -r mcs -X stuff '/save-all\n/save-off\n'
gsutil -m cp -R $${BASH_SOURCE%/*}/world gs://${BUCKET_PREFIX}-minecraft-backup/$(date "+%Y%m%d-%H%M%S")-world
screen -r mcs -X stuff '/save-on\n'
echo "saved file at $now"
EOF

# skip startup script if already complete
if [[ -f $CL_CO_PATH/startup_finished ]]; then
  echo "Every time starting!"
  crontab -l
  mount /dev/disk/by-id/google-minecraft-disk $MC_PATH
  cd $MC_PATH
  pwd
  sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui
  echo "Onboarding complete, skip startup script"
  exit
  
else  # Run first boot scripts
  echo "Running first boot scripts"
  sudo chmod +x $SCRIPT_PATH/first_start.sh $SCRIPT_PATH/backup.sh
  bash $SCRIPT_PATH/first_start.sh
  #crontab -l | { cat; echo "0 */4 * * * $MC_PATH/backup.sh"; } | crontab -
fi