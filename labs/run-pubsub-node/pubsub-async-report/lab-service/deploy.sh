chmod u+x deploy.sh
export REGION=europe-north1

gcloud pubsub topics create new-lab-report
gcloud services enable run.googleapis.com
git clone https://github.com/rosera/pet-theory.git
cd pet-theory/lab05/lab-service

npm install express
npm install body-parser
npm install @google-cloud/pubsub

gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service
gcloud run deploy lab-report-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --max-instances=1

export LAB_REPORT_SERVICE_URL=$(gcloud run services describe lab-report-service --platform managed --region $REGION --format="value(status.address.url)")
echo $LAB_REPORT_SERVICE_URL

chmod u+x post-reports.sh
./post-reports.sh

cd ~/pet-theory/lab05/email-service
npm install express
npm install body-parser