export REGION=europe-north1
export PROJECT=$GOOGLE_CLOUD_PROJECT

gcloud services enable run.googleapis.com

gcloud config set compute/region $REGION
gcloud config set run/region $REGION
mkdir helloworld && cd helloworld

gcloud builds submit --tag gcr.io/$PROJECT/helloworld
gcloud run deploy --image gcr.io/$PROJECT/helloworld

gcloud compute addresses create example-ip --ip-version=IPV4 --global
gcloud compute addresses describe example-ip --format="get(address)" --global

gcloud compute network-endpoint-groups create myneg \
  --region=$REGION
  --network-endpoint-type=serverless \
  --cloud-run-service=helloworld

gcloud compute backend-service create mybackendservice --global

gcloud compute backend-services add-backend mybackendservice \
  --global
  --network-endpoint-group=myneg \
  --network-endpoint-group-region=$REGION

gcloud compute url-maps create myurlmap --default-service mybackendservice
gcloud compute target-http-proxies create mytargetproxy --url-map=myurlmap
gcloud compute forwarding-rules create myforwardingrule \
  --address=example-ip \
  --target-http-proxy=mytargetproxy \
  --global \
  --ports=80

