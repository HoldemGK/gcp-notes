# gcp-projects
MyGCP

Documentation - https://cloud.google.com/docs/tutorials

Set up Terraform Service Account

`export TF_ADMIN=${USER}-terraform-admin`

`gcloud iam service-accounts create terraform \

  --display-name "Terraform admin account"`

`gcloud projects add-iam-policy-binding ${TF_ADMIN} \

  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \

  --role roles/editor`

`gcloud iam service-accounts keys create key.json \

  --iam-account terraform@${TF_ADMIN}.iam.gserviceaccount.com`

GCP privilege escalation - [Gitlab Red Team](https://about.gitlab.com/blog/2020/02/12/plundering-gcp-escalating-privileges-in-google-cloud-platform/?utm_medium=social&utm_source=twitter&utm_campaign=blog)
