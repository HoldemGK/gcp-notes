#!/bin/bash

sudo useradd -m steam && cd /home/steam
sudo apt update
sudo dpkg --add-architecture i386
sudo apt update
# Agree licanse
echo steam steam/license note '' | sudo debconf-set-selections
echo steam steam/question select "I AGREE" | sudo debconf-set-selections

sudo apt install lib32gcc1 libsdl2-2.0-0:i386 steamcmd -y && \
sudo ln -s /usr/games/steamcmd steamcmd && \
sudo -iu steam
./steamcmd
login anonymous
force_install_dir /home/steam/Valheim
app_update 896660 validate
exit
cd Valheim
cp start_server.sh start_server_copy.sh
./start_server_copy.sh
