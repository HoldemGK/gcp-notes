export REGION=europe-north1
export PRJ=$GOOGLE_CLOUD_PROJECT
export IMG=gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter-go

git clone https://github.com/Deleplace/pet-theory.git
cd pet-theory/lab03

go build -o server

cat Dockerfile

gcloud builds submit --tag $IMG

gcloud run deploy pdf-converter-go \
  --image $IMG \
  --platform managed \
  --region $REGION \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --set-env-vars PDF_BUCKET=$PRJ-process \
  --max-instances=3

gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$PRJ-upload

gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"

gcloud run services add-iam-policy-binding pdf-converter \
  --member=serviceAccount:pubsub-cloud-run-invoker@$PRJ.iam.gserviceaccount.com \
  --role=roles/run.invoker \
  --region $REGION
  --platform managed

PROJECT_NUMBER=$(gcloud projects list \
 --format="value(PROJECT_NUMBER)" \
 --filter="$GOOGLE_CLOUD_PROJECT")

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator

SERVICE_URL=$(gcloud run services describe pdf-converter \
  --platform managed \
  --region $REGION \
  --format "value(status.url)")

curl -X GET $SERVICE_URL

curl -X GET -H "Authorization: Bearer $(gcloud auth print-identitiy-token)" $SERVICE_URL

gcloud pubsub subscriptions create pdf-conv-sub \
  --topic new-doc \
  --push-endpoint=$SERVICE_URL \
  --push-auth-service-account=pubsub-cloud-run-invoker@$PRJ.iam.gserviceaccount.com
  