hub                             = "prod"
address_space                   = "10.24.239.0/28"
postgres_subnet_address_space   = "10.24.239.48/28"
extended_address_space          = "10.24.239.160/28"
logic_apps_address_space        = "10.24.239.176/29"
virtual_machine_admins          = ["675f1c23-3e46-4cf8-867b-747eb60fe89d", "d8b336b1-91fb-4fa6-bbe2-1f197c0d52c8", "14f9cf0e-8327-4f12-9d2c-f7e7eb05629d", "50132661-6997-484e-b0fd-5ec1052afabb", "e7ea2042-4ced-45dd-8ae3-e051c6551789", "1f9e0772-2158-4377-9515-f749044d3178"]
virtual_machine_users           = []
storage_account_contributor_ids = ["4908856e-c987-4ad8-b519-a5480a1fcc12"]
defender_enable                 = true
defender_scan                   = true
log_analytics_workspace_name    = "hmcts-prod"
log_analytics_workspace_rg      = "oms-automation"
log_analytics_subscription_id   = "8999dec3-0104-4a27-94ee-6588559729d1"

migration_vms = {
  prddartsmig01 = {
    ip_address = "10.24.239.6"
  }
  prddartsassess = {
    ip_address     = "10.24.239.5"
    data_disk_size = "2000"
  }
  prddartsassure = {
    ip_address     = "10.24.239.164"
    subnet         = "migration-subnet-extended"
    data_disk_size = "1000"
    sku            = "Standard_D32ds_v5"
  }
  prddartsoracle = {
    ip_address     = "10.24.239.166"
    subnet         = "migration-subnet-extended"
    data_disk_size = "2000"
  }
  prddartsunstr = {
    ip_address = "10.24.239.168"
    subnet     = "migration-subnet-extended"
    sku        = "Standard_D4ds_v5"
  }
  prddartsmig04 = {
    ip_address = "10.24.239.9"
  }
  prddartsmig05 = {
    ip_address = "10.24.239.10"
  }
  prddartsmig02 = {
    ip_address = "10.24.239.7"
  }
  prddartsmig03 = {
    ip_address = "10.24.239.8"
  }
}

firewall_route_ranges = [
  "10.23.253.177/32",
  "10.23.253.178/32",
  "10.23.253.241/32",
  "10.23.253.242/32",
  "10.23.253.243/32",
  "10.23.253.244/32",
  "10.23.253.177/32",
  "10.23.253.178/32",
  "10.23.253.241/32",
  "10.23.253.243/32",
  "10.23.253.244/32",
  "10.63.111.175/32",
  "10.63.111.187/32",
  "10.63.111.176/32",
  "10.63.111.188/32",
  "10.65.64.155/32",
  "10.65.64.180/32",
  "10.65.64.156/32",
  "10.65.64.181/32",
  "10.100.197.200/32",
  "10.100.197.200/32"
]

migration_linux_vms = {
  prddartsmigdb01 = {
    ip_address = "10.24.239.11"
  }
}
migration_gitlab_vms = {
  prddartsgitlab = {
    ip_address = "10.24.239.169"
    subnet     = "migration-subnet-extended"
  }
}
migration_docker_vms = {
  prddartsmigdock = {
    ip_address = "10.24.239.167"
    subnet     = "migration-subnet-extended"
  }
}
migration_linux_vms2 = {
  prddartsmigdb02 = {
    ip_address        = "10.24.239.13"
    availability_zone = "2"
  }
}
oracle_linux_vms = {
  prddartsmigora01 = {
    ip_address = "10.24.239.12"
  }
}

sku_name = "Premium"
family   = "P"
capacity = "1"

palo_networks = {
  mgmt = {
    address_space      = "10.24.239.32/28"
    public_ip_required = true
    nsg_deny_inbound   = true
  }
  trust = {
    address_space        = "10.24.239.16/28"
    enable_ip_forwarding = true
  }
}

install_azure_monitor = true
