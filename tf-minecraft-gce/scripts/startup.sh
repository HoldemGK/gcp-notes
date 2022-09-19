#!/bin/bash
mount /dev/disk/by-id/google-minecraft-disk /home/minecraft
cd /home/minecraft
sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui