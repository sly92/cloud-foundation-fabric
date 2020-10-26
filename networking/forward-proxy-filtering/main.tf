/*
TODO:
* review org policies
  - constraints/compute.restrictSharedVpcHostProjects
  - constraints/compute.restrictSharedVpcSubnetworks
  - constraints/compute.restrictVpnPeerIPs

  - Permissions / groups
*/

###############################################################################
#                           netops folder resources                           #
###############################################################################

module "folder-netops" {
  source = "../../modules/folders"
  parent = var.root_node
  names  = ["netops"]
}

module "project-host" {
  source          = "../../modules/project"
  billing_account = var.billing_account
  name            = "host"
  parent          = module.folder-netops.id
  prefix          = var.prefix
  services        = ["compute.googleapis.com", "dns.googleapis.com"]
  shared_vpc_host_config = {
    enabled          = true
    service_projects = []
  }
}

module "vpc" {
  source     = "../../modules/net-vpc"
  project_id = module.project-host.project_id
  name       = "vpc"
  subnets = [
    {
      name               = "apps"
      ip_cidr_range      = var.cidrs.apps
      region             = var.region
      secondary_ip_range = null
    },
    {
      name               = "proxy"
      ip_cidr_range      = var.cidrs.proxy
      region             = var.region
      secondary_ip_range = null
    }
  ]
}

module "firewall" {
  source     = "../../modules/net-vpc-firewall"
  project_id = module.project-host.project_id
  network    = module.vpc.name
  custom_rules = {
    allow-squid-tag = {
      description          = "Allow squid"
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = [var.cidrs.apps]
      targets              = ["squid"]
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = [3128] }]
      extra_attributes     = {}
    }
  }
}

module "nat" {
  source                = "../../modules/net-cloudnat"
  project_id            = module.project-host.project_id
  region                = var.region
  name                  = "default"
  router_network        = module.vpc.name
  config_source_subnets = "LIST_OF_SUBNETWORKS"
  subnetworks = [
    {
      self_link            = module.vpc.subnet_self_links["${var.region}/proxy"]
      config_source_ranges = ["ALL_IP_RANGES"]
      secondary_ranges     = null
    }
  ]
}

module "vm-app" {
  source     = "../../modules/compute-vm"
  project_id = module.project-service-app1.project_id
  region     = var.region
  name       = "app"
  tags       = ["ssh"]
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/apps"]
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  instance_count = 1
}

module "vm-proxy" {
  source        = "../../modules/compute-vm"
  project_id    = module.project-host.project_id
  region        = var.region
  name          = "squid"
  tags          = ["squid", "ssh"]
  instance_type = "n1-standard-1"
  network_interfaces = [{
    network    = module.vpc.self_link
    subnetwork = module.vpc.subnet_self_links["${var.region}/proxy"]
    nat        = false
    addresses  = null
    alias_ips  = null
  }]
  boot_disk = {
    image = "projects/debian-cloud/global/images/family/debian-10"
    type  = "pd-ssd"
    size  = 10
  }
  metadata = {
    startup-script = templatefile("startup.sh", {
      allowlist = [
        ".github.com"
      ]
      clients = [
        var.cidrs.apps
      ]
    })
  }
  instance_count = 1
}

module "private-dns" {
  source          = "../../modules/dns"
  project_id      = module.project-host.project_id
  type            = "private"
  name            = "internal"
  domain          = "internal."
  client_networks = [module.vpc.self_link]
  recordsets = [{
    name    = "proxy"
    type    = "A"
    ttl     = 300
    records = module.vm-proxy.internal_ips
  }]
}

###############################################################################
#                            apps folder resources                            #
###############################################################################

module "folder-apps" {
  source = "../../modules/folders"
  parent = var.root_node
  names  = ["apps"]

  policy_list = {
    "constraints/compute.vmExternalIpAccess" = {
      inherit_from_parent = false
      suggested_value     = null
      status              = false
      values              = []
    }
    "constraints/compute.restrictCloudNATUsage" = {
      inherit_from_parent = false
      suggested_value     = null
      status              = false
      values              = []
    }
  }
}

module "project-service-app1" {
  source          = "../../modules/project"
  billing_account = var.billing_account
  name            = "app1"
  parent          = module.folder-apps.id
  prefix          = var.prefix
  services        = ["compute.googleapis.com"]
  shared_vpc_service_config = {
    attach       = true
    host_project = module.project-host.project_id
  }
}
