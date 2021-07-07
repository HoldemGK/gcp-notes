"""A Google Cloud Python Pulumi program"""

import pulumi
import pulumi_gcp as gcp
config = pulumi.Config()
instance_zone = config.require('zone')
instance_name = config.require('instance_name')
instance_type = config.require('instance_type')
instance_image = config.require('instance_image')
instance_disk_size = config.require('instance_disk_size')
network_tags = config.require('network_tags')
firewall_name = config.require('firewall_name')

firewall = compute.Firewall(firewall_name,
  network = "default",
  allows = [
        gcp.compute.FirewallAllowArgs(
            protocol="udp",
            ports=["2456-2457"]),
        gcp.compute.FirewallAllowArgs(
            protocol="tcp",
            ports=["2456-2457"]
        )],
  source_ranges = ["0.0.0.0/0"])

instance = gcp.compute.Instance(instance_name,
    machine_type=instance_type,
    zone=instance_zone,
    tags=network_tags,
    boot_disk=gcp.compute.InstanceBootDiskArgs(
        initialize_params=gcp.compute.InstanceBootDiskInitializeParamsArgs(
            image=instance_image,
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
