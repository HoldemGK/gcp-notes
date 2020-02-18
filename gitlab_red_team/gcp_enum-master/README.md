# gcp_enum

A simple bash script to enumerate Google Cloud Platform environments. The script utilizes `gcloud`, `gsutil`, and `curl` commands to collect information from various GCP APIs. The commands will use the current "Application Default Credentials".

An attacker could use a script like this to understand the level of access they have from something like a compromised compute instance.

Defenders can use this script to simulate enumeration and build detection capabilities.

All commands are information-gathering only - they do not attempt to make any changes to the environment. However, you should fully audit this script yourself before running in your own environment.

# Usage

Simply run the script. An output folder beginning with `out-gcp-enum` will be created in the working directory.

It is likely that many of the commands will fail due to permissions issues. To improve the user experience, `STDERR` is not displayed and a generic failure message is displayed in these cases. If you are troubleshooting, you can run the script with a `-d` argument to display all error messages.
