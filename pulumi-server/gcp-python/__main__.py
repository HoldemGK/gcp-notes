"""A Google Cloud Python Pulumi program"""

import pulumi
import pulumi_gcp as gcp

default_account = gcp.service_account.Account("defaultAccount",
    account_id="service_account_id",
    display_name="Service Account")
default_instance = gcp.compute.Instance("dedicated-server",
    machine_type="e2-medium",
    zone="europe-north1-b",
    tags=[
        "steam-server"
    ],
    boot_disk=gcp.compute.InstanceBootDiskArgs(
        initialize_params=gcp.compute.InstanceBootDiskInitializeParamsArgs(
            image="ubuntu-os-cloud/ubuntu-2004-lts",
        ),
    ),
    scratch_disks=[gcp.compute.InstanceScratchDiskArgs(
        interface="SCSI",
    )],
    network_interfaces=[gcp.compute.InstanceNetworkInterfaceArgs(
        network="default",
        access_configs=[gcp.compute.InstanceNetworkInterfaceAccessConfigArgs()],
    )],
    metadata={
        "foo": "bar",
    },
    metadata_startup_script="echo hi > /test.txt",
    service_account=gcp.compute.InstanceServiceAccountArgs(
        email=default_account.email,
        scopes=["cloud-platform"],
    ))
