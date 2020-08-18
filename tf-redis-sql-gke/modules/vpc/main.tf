module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 2.3"

    project_id   = var.project
    network_name = var.network
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name              = var.subnetwork
            subnet_ip                = "10.183.0.0/20"
            subnet_region            = var.region
            subnet_private_access    = "true"
            subnet_flow_logs         = "true"
            description              = var.subnet_description
        }
    ]

    secondary_ranges = {
        (var.subnetwork) = [
            {
                range_name    = join("-", [var.subnetwork, "pods"])
                ip_cidr_range = "10.184.0.0/14"
            },
            {
                range_name    = join("-", [var.subnetwork, "services"])
                ip_cidr_range = "10.188.0.0/20"
            },
        ]
    }

}
