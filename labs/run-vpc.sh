export REGION=europe-north1
export PRJ=$GOOGLE_CLOUD_PROJECT
export IMG_BUILDER="gcr.io/buildpacks/builder"
export IMG_SAMPLE="gcr.io/$GOOGLE_CLOUD_PROJECT/sample-go"

gcloud services enable run.googleapis.com

gcloud config set compute/region $REGION
git clone https://github.com/GoogleCloudPlatform/buildpack-samples.git
cp -R buildpack-samples/sample-go buildpack-samples/sample-go-service
cd buildpack-samples/sample-go

pack build --builder=$IMG_BUILDER sample-go

docker run -it -e PORT=8080 -p 8080:8080 sample-go
gcloud auth configure-docker

pack config default-builder $IMG_BUILDER:v1
pack build --publish $IMG_SAMPLE

gcloud compute networks list
gcloud compute networks subnets create mysubnet \
  --range=192.168.0.0/28 \
  --network=default \
  --region=$REGION

gcloud compute networks vpc-access connectors create myconnector \
  --region=$REGION \
  --subnet-project=$PRJ \
  --subnet=mysubnet

gcloud compute routers create myrouter --network default --region=$REGION
gcloud compute addresses create myoriginip --region=$REGION
gcloud compute routers nats create mynat \
  --router=myrouter \
  --region=$REGION \
  --nat-custom-subnet-ip-ranges=mysubnet \
  --nat-external-ip-pool=myoriginip

gcloud run deploy sample-go \
  --image=$IMG_SAMPLE \
  --vpc-connector=myconnector \
  --vpc-egress=all-traffic \
  --region $REGION \
  --allow-unauthenticated

SERVICE_A_SAMPLE_GO=$(gcloud run services describe sample-go \
  --platform managed \
  --region $REGION \
  --format "value(status.url)")

# Create a receiving service
cd ~/buildpack-samples/sample-go-service

gcloud run deploy sample-go-service \
  --source . \
  --port=8081 \
  --vpc-connector myconnector \
  --ingress=internal \
  --region $REGION \
  --allow-unauthenticated

SERVICE_B_SAMPLE_GO=$(gcloud run services describe sample-go-service \
  --platform managed \
  --region $REGION \
  --format "value(status.url)")

# Test service communication
gcloud run services update sample-go \
  --region $REGION \
  --set-env-vars=SERVICE_B_URL=$SERVICE_B_SAMPLE_GO_SERVICE

curl ${SERVICE_A_SAMPLE_GO}/service

# Verify the originating IP address of the calling service
gcloud run services update sample-go \
  --region $REGION \
  --set-env-vars=SERVICE_B_URL=http://curlmyip.org

curl ${SERVICE_A_SAMPLE_GO}/service