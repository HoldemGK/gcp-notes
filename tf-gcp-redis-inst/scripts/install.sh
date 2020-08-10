#! bin/bash

sudo yum install epel-release
sudo yum update
sudo yum install redis
sudo systemctl start redis
sudo systemctl enable redis