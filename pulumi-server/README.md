# Pulumi project Game server

If gcloud is not configured to interact with your Google Cloud project, set it with the config command using the project’s ID:

`bash
gcloud config set project $PROJECT
`
Next, Pulumi requires default application credentials to interact with your Google Cloud resources, so run auth application-default login command to obtain those credentials.

`bash
gcloud auth application-default login
`
The pulumi new command creates a new Pulumi project with some basic scaffolding based on the cloud and language specified.
`bash
pulumi new gcp-python
`
