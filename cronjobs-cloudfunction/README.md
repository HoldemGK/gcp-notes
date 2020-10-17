# Cron Jobs to the Cloud
Geting top news from HackerNews by API

### Seting variables
```
export PROJECT=$(gcloud info --format='value(config.project)')
export REGION=us-central1
```

### Deploy CloudFunction
```
gcloud functions deploy scan_hacker_news \
  --runtime python37
  --trigger-http
```

### Scheduler job
```
gcloud scheduler jobs create http email_job \
  --schedule="0 0 * * *" \
  --uri=https://$REGION-$PROJECT.cloudfunctions.net/scan_hacker_news
```

### List of jobs
```
gcloud scheduler jobs list
```

### Running job immediately
```
gcloud scheduler jobs run email_job
```
