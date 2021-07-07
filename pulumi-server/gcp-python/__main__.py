"""A Google Cloud Python Pulumi program"""

import pulumi
import pulumi_gcp as gcp
config = pulumi.Config()
instance_zone = config.require('zone')
instance_name = config.require('instance_name')
instance_type = config.require('instance_type')
instance_image = config.require('instance_image')
instance_disk_size = config.require('instance_disk_size')


instance = gcp.compute.Instance(instance_name,
    machine_type=instance_type,
    zone=instance_zone,
    tags=[
        "steam-server"
    ],
    boot_disk=gcp.compute.InstanceBootDiskArgs(
        initialize_params=gcp.compute.InstanceBootDiskInitializeParamsArgs(
            image="ubuntu-os-cloud/ubuntu-2004-lts",
        ),
    ),
    network_interfaces=[gcp.compute.InstanceNetworkInterfaceArgs(
        network="default",
        access_configs=[gcp.compute.InstanceNetworkInterfaceAccessConfigArgs()],
    )],
    metadata={
        "foo": "bar",
    },
    metadata_startup_script="echo hi > /test.txt",
    ))
