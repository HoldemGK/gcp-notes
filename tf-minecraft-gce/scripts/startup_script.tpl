#!/bin/bash
# Setup console and startup-script logging
LOG_FILE=/var/log/minecraft/startup_script.log
mkdir -p  /var/log/minecraft
[[ -f $LOG_FILE ]] || /usr/bin/touch $LOG_FILE
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1

# skip startup script if already complete
if [[ -f /home/minecraft/cloud/config/startup_finished ]]; then
  echo "Every time starting!"
  crontab -l
  mount /dev/disk/by-id/google-minecraft-disk /home/minecraft
  cd /home/minecraft
  sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui
  echo "Onboarding complete, skip startup script"
  exit
fi

# Create runtime configuration on first boot
cat << 'EOF' > /home/minecraft/cloud/config/first_start.sh
#!/bin/bash
sudo mkdir -p /home/minecraft/cloud/config
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-minecraft-disk
sudo mount -o discard,defaults /dev/disk/by-id/google-minecraft-disk /home/minecraft
sudo apt-get update
sudo apt-get install -y default-jre-headless

# Backup prepare
sudo chmod 755 /home/minecraft/backup.sh
{ crontab -l; echo '0 */4 * * * /home/minecraft/backup.sh'; } | crontab -
      
cd /home/minecraft
sudo apt-get install wget -y
sudo wget https://piston-data.mojang.com/v1/objects/c9df48efed58511cdd0213c56b9013a7b5c9ac1f/server.jar
sudo java -Xmx1024M -Xms1024M -jar server.jar nogui
sed -i "s/eula=false/eula=true/g" ./eula.txt
sudo apt-get install -y screen
touch /home/minecraft/cloud/config/startup_finished
sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui &
EOF

# Create backup script on first boot
cat << 'EOF' > /home/minecraft/backup.sh
#!/bin/bash
now=$(date +'%Y%m%d%H%M%S')
screen -r mcs -X stuff '/save-all\n/save-off\n'
gsutil -m cp -R $${BASH_SOURCE%/*}/world gs://${BUCKET_PREFIX}-minecraft-backup/$(date "+%Y%m%d-%H%M%S")-world
screen -r mcs -X stuff '/save-on\n'
echo "saved file at $now"
EOF

# Run first boot scripts
if [[ -f /home/minecraft/cloud/config/startup_finished ]]; then
    echo "Running first boot scripts"
    chmod +x /home/minecraft/cloud/config/first_start.sh
    bash /home/minecraft/cloud/config/first_start.sh
fi