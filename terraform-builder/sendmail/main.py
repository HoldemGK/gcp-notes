from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
import os
import json
import base64

def get_secret_version(project_id, secret_id):
    from google.cloud import secretmanager

    client = secretmanager.SecretManagerServiceClient()
    name = client.secret_version_path(project_id, secret_id, "latest")

    # Get the secret
    response = client.access_secret_version(name)

    return response.payload.data.decode('UTF-8').rstrip("\n")

def sendmail(event, context):
    print("Received pubsub message")
    print(event)
    if 'data' in event:
        build = json.loads(str(base64.b64decode(json.dumps(event['data'])).decode('utf-8')))
        print(build)
        try:
            project_id = os.environ['PROJECT_ID']
        except:
            raise SystemExit('PROJECT_ID environment variable not set.')
        sender = os.environ['SENDER']
        recipient = os.environ['RECIPIENT']
        if 'digest' in build.keys():
            digest = build['digest']
        else:
            digest = ""
        if 'tag' in build.keys():
            tag = build['tag']
            message = Mail(
                from_email = sender,
                to_emails = recipient,
                subject = '{} Container Registry Change {}'.format(project_id,tag),
                html_content = '{} Container Registry has had a container update: {} {} {}'.format(project_id,build['action'],tag,digest) )
            try:
                sg = SendGridAPIClient(get_secret_version(project_id, "sendgridapikey"))
                response = sg.send(message)
                print(response.status_code)
                print(response.body)
                print(response.headers)
            except Exception as e:
                print(e.message)
    else:
        raise SystemExit('data key not present in JSON')

if __name__ == "__main__":
    event = {'data':{"action":"INSERT","digest":"gcr.io/project_id/terraform@sha256:hash","tag":"gcr.io/project_id/terraform:latest"}}
    sendmail(event,None)
