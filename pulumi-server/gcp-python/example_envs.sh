#!/bin/bash

pulumi config set gcp:project myproject
pulumi config set gcp:region us-central1
pulumi config set gcp:zone us-central1-a
pulumi config set instance_name dev
pulumi config set instance_type n1-highmem-2
pulumi config set instance_image ubuntu-1604-xenial-v20191010
pulumi config set instance_disk_size 50
