export REGION="us-west1"
export IMG_BIL=gcr.io/$GOOGLE_CLOUD_PROJECT/billing-staging-api
export IMG_FR=gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging
export IMG_BIL_PRD=gcr.io/$GOOGLE_CLOUD_PROJECT/billing-prod-api
export IMG_FR_PRD=gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-prod

# gcloud config set project \
# $(gcloud projects list --format='value(PROJECT_ID)' \
# --filter='qwiklabs-gcp')

gcloud config set run/region $REGION
gcloud config set run/platform managed

git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab07

# Set up a Rest API for the billing service
cd unit-api-billing
gcloud builds submit --tag $IMG_BIL:0.1

gcloud run deploy billing-service \
  --image $IMG_BIL:0.1 \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --description="Public billing service"

# Set up a Frontend Service
cd ../staging-frontend-billing
gcloud builds submit --tag $IMG_FR:0.1

gcloud run deploy frontend-staging-service-294 \
  --image $IMG_FR:0.1 \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --description="Frontend staging service"

# Deploy a private service
cd ../staging-api-billing
gcloud builds submit --tag $IMG_BIL:0.2

gcloud run deploy private-billing-service-278 \
  --image $IMG_BIL:0.2 \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --description="Private billing service"

export BILLING_URL=$(gcloud run services describe private-billing-service-278 \
  --platform managed \
  --region $REGION \
  --format "value(status.url)")

curl -X get -H "Authorization: Bearer $(gcloud auth print-identity-token)" $BILLING_URL

# Create SA
gcloud iam service-accounts create billing-service-sa-991 \
  --display-name "Billing Service Cloud Run"

# gcloud beta run services add-iam-policy-binding billing-service \
#   --member=serviceAccount:billing-service-sa-991@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
#   --role=roles/run.invoker --platform managed --region $REGION

# Deploy prd billing service
cd ../prod-api-billing
gcloud builds submit --tag $IMG_BIL_PRD:0.1

gcloud run deploy billing-prod-service-218 \
  --image $IMG_BIL_PRD:0.1 \
  --platform managed \
  --region $REGION \
  --no-allow-unauthenticated \
  --description="Billing production service" \
  --service-account=billing-service-sa-991@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

PROD_BILLING_URL=$(gcloud run services describe billing-prod-service-218 \
  --platform managed \
  --region REGION \
  --format "value(status.url)")

curl -X get -H "Authorization: Bearer \
$(gcloud auth print-identity-token)" \
$PROD_BILLING_URL

# Create Front SA
gcloud iam service-accounts create frontend-service-sa-684 \
  --display-name "Billing Service Cloud Run Invoker"

# Redeploy the frontend service
cd ../prod-frontend-billing
gcloud builds submit --tag $IMG_FR_PRD:0.1

gcloud run deploy frontend-prod-service-303 \
  --image $IMG_FR_PRD:0.1 \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --description="Frontend production service"

gcloud beta run services add-iam-policy-binding frontend-prod-service-303 \
  --member=serviceAccount:frontend-service-sa-684@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --role=roles/run.invoker --platform managed --region $REGION