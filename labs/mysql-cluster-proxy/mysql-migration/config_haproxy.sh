#!/bin/bash
cat <<EOF >  /etc/haproxy/haproxy.cfg
######### HAProxy Config file #########

global
       log /dev/log    local0
       log /dev/log    local1 notice
       chroot /var/lib/haproxy
       stats socket /run/haproxy/admin.sock mode 660 level admin
       stats timeout 30s
       user haproxy
       group haproxy
       daemon

defaults
       log     global
       timeout connect 3000
       timeout client  5000
       timeout server  5000

listen mysql-cluster
bind 127.0.0.1:3306,$(curl  \
    http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip \
    -H 'Metadata-Flavor: Google'):3306
       mode tcp
       option mysql-check user haproxy_check
       balance roundrobin

       # Server number 1
       server source-primary source-mysql-primary:3306 check

       # Server number 2
       # server target-primary target-mysql-primary:3306 check

listen stats
       bind 0.0.0.0:80
       mode http
       stats enable
       stats uri /haproxy
       stats realm Strictly\ Private
       stats auth mysqlproxy:MySQLProxy12!
EOF
