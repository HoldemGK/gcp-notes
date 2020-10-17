# Cron Jobs to the Cloud
Geting top news from HackerNews by API

## Get the top stories from the API

## Iterate over every story

## If any of their titles match "cloud" send email

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
  --uri=https://us-central1-project.cloudfunctions.net/scan_hacker_news
```

### List of jobs
```
gcloud scheduler jobs list
```

### Running job immediately
```
gcloud scheduler jobs run email_job
```
