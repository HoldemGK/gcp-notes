#!/usr/bin/bash

arrWORKER_NAMES=($1)
arrWORKER_IPS=($2)

echo worker_nodes = { >> ips.auto.tfvars
for (( i=0; i<${#arrWORKER_NAMES[@]}; i++ ))
    do  
        echo ${arrWORKER_NAMES[i]} = \"${arrWORKER_IPS[i]}\" >> ips.auto.tfvars
    done
echo } >> ips.auto.tfvars

