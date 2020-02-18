# gcp_firewall_enum

This tool analyzes the output of several `gcloud` commands to determine which compute instances have network ports exposed to the public Internet. Several files are created upon analysis:

- applied-rules.csv: A comma-separated file showing compute instance name, external IP address, allowed TCP ports, allowed UDP ports.
- run-nmap.sh: A targeted nmap script to scan each instance only on the exposed ports.
- run-masscan.sh: A targeted masscan script to scan all TCP ports on compute instances with rules exposing the entire TCP port range.

## Usage

### Single Project

You can use this tool to analyze a single GCP project or many projects at once.

The `gcp_firewall_enum.py` python script performs offline analysis only. You'll need the proper permissions to export the data via `gcloud` prior to running.

To analyze a single project, first you would run the following `gcloud` commands from an authorized session.

```
gcloud compute firewall-rules list \
    --format="json(name,allowed[].map().firewall_rule().list(),network,
        targetServiceAccounts.list(),targetTags.list())" \
    --filter="direction:INGRESS AND disabled:False AND
        sourceRanges.list():0.0.0.0/0 AND
        allowed[].map().firewall_rule().list():*" \
    | tee ./firewall-rules.json


gcloud compute instances list \
    --format="json(id,name,networkInterfaces[].accessConfigs[0].natIP,
        serviceAccounts[].email,tags.items[],networkInterfaces[].network)" \
    --filter="networkInterfaces[].accessConfigs[0].type:ONE_TO_ONE_NAT
        AND status:running" \
    | tee ./compute-instances.json
```

This should create the files `firewall-rules.json` and `compute-instances.json` in your current working directory.

Then, you can run the following command to perform the analysis.

```
./gcp_firewall_enum.py --single ./
```

### Multiple Projects

You can also use the tool to analyze many projects at once, outputting single files with the consolidated results.

The first step is to gather the required output files for each and every project, and place them in individual subdirectories. This is automated for you in the included [gather-json.sh](gather-json.sh) bash script.

If you have a ton of projects, you'll probably see errors for some that don't have the compute API enabled. This is fine, as it means there is nothing in those projects to analyze.

Once the gather script completes, you can run the following command targeting the `json-data` directory that was created.

```
./gcp_firewall_enum.py --multi ./json-data
```

### Advanced Features

Perhaps you have a lot of programmatically-generated compute instances that you don't want to scan. If they have a consistent naming strategy, you can use the `--exclude` function to feed in a python regex. We'll go ahead and skip any instances that match.

For example, if you have a lot of instances with a name like `super-secure-afe00`, you can try the command as follows:

```
./gcp_firewall_enum.py -m json-data/ --exclude 'super-secure-[a-f0-9]{5}'
```

### Design Decisions

This tool was created specifically to allow large-scale port scanning of GCP resources, while avoiding time-consuming scanning of ports that would simply be blocked by Google's firewalls.

The `gcloud` commands used only pull data for the following:

- Compute instances that are running and have external IP addresses
- Ingress firewall rules that are enabled and have a source range of '0.0.0.0/0', meaning exposed to the entire Internet

The nmap script will scan only the top TCP and UDP ports for instances with a rule that permits ALL. A separate masscan script is created that will scan the entire TCP range for these specific instances.

Perhaps your use case differs from these decisions, in which case you would need to make some modifications.

### Project State
This tool is in an early POC state. It works. We may refine or add features with a focus on automation. Or we may simply tweak it to plug it into another automation framework to use internally.

In the spirit of our [public by default](https://about.gitlab.com/handbook/values/#public-by-default) value, it's available to use as you see fit in its current state.

If you like this, hate it, or wish it was different - please let us know by opening an [issue](https://gitlab.com/gitlab-com/gl-security/gl-redteam/gcp_firewall_enum/issues).

Thanks!
