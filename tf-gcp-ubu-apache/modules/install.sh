#! /bin/bash

sudo apt-get update
sudo apt-get install apache2 -y
sudo adduser jenkins
sudo chown -R jenkins:jenkins /var/www
echo '<!doctype html><html><body><h1>Hello World!</h1></body></html>' | sudo tee /var/www/html/index.html
