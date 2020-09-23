# gcp-projects
MyGCP

* Documentation - https://cloud.google.com/docs/tutorials

### Set up Terraform Service Account

```
export PROJECT=$(gcloud info --format='value(config.project)')

gcloud iam service-accounts create terraform \

   --display-name "Terraform admin account"

gcloud projects add-iam-policy-binding ${PROJECT} \

   --member serviceAccount:terraform@${PROJECT}.iam.gserviceaccount.com \

   --role roles/editor

gcloud iam service-accounts keys create key.json \

   --iam-account terraform@${PROJECT}.iam.gserviceaccount.com
```

### Get Zone from instance

```
#! /bin/bash

ZONE=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google")

sed -i "s|zone-here|$ZONE|" /var/www/html/index.html
```

* GCP privilege escalation - [Gitlab Red Team](https://about.gitlab.com/blog/2020/02/12/plundering-gcp-escalating-privileges-in-google-cloud-platform/?utm_medium=social&utm_source=twitter&utm_campaign=blog)
