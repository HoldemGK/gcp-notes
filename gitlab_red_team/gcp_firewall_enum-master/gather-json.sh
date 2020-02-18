#!/bin/bash

# Script to gather all necessary json data for firewall analysis

for i in `gcloud projects list --format="get(projectId)"`; do
    mkdir -p ./json-data/"$i"
    
    echo scraping project "$i"

    gcloud compute firewall-rules list \
        --format="json(name,allowed[].map().firewall_rule().list(),network,
            targetServiceAccounts.list(),targetTags.list())" \
        --filter="direction:INGRESS AND disabled:False AND
            sourceRanges.list():0.0.0.0/0 AND
            allowed[].map().firewall_rule().list():*" \
        --quiet \
        --project="$i" \
        > ./json-data/"$i"/firewall-rules.json


    gcloud compute instances list \
        --format="json(name,networkInterfaces[].accessConfigs[0].natIP,
            serviceAccounts[].email,tags.items[],networkInterfaces[].network)" \
        --filter="networkInterfaces[].accessConfigs[0].type:ONE_TO_ONE_NAT
            AND status:running" \
        --quiet \
        --project="$i" \
        > ./json-data/"$i"/compute-instances.json

done
