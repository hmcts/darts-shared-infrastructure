hub                             = "prod"
address_space                   = "10.24.239.0/28"
postgres_subnet_address_space   = "10.24.239.48/28"
# virtual_machine_admins          = ["675f1c23-3e46-4cf8-867b-747eb60fe89d", "d8b336b1-91fb-4fa6-bbe2-1f197c0d52c8", "14f9cf0e-8327-4f12-9d2c-f7e7eb05629d", "50132661-6997-484e-b0fd-5ec1052afabb", "e7ea2042-4ced-45dd-8ae3-e051c6551789"]
virtual_machine_users           = []
storage_account_contributor_ids = []
defender_enable                 = true
defender_scan                   = true

virtual_machine_admins = {
  user1 = {
    guid = "675f1c23-3e46-4cf8-867b-747eb60fe89d"
  }
  user2 = {
    guid = "d8b336b1-91fb-4fa6-bbe2-1f197c0d52c8"
  }
  user3 = {
    guid = "14f9cf0e-8327-4f12-9d2c-f7e7eb05629d"
  }
  user1 = {
    guid =  "50132661-6997-484e-b0fd-5ec1052afabb"
  }
  prddartsmig05 = {
    guid = "e7ea2042-4ced-45dd-8ae3-e051c6551789"
  }
}

migration_vms = {
  prddartsmig01 = {
    ip_address = "10.24.239.6"
  }
  prddartsmig02 = {
    ip_address = "10.24.239.7"
  }
  prddartsmig03 = {
    ip_address = "10.24.239.8"
  }
  prddartsmig04 = {
    ip_address = "10.24.239.9"
  }
  prddartsmig05 = {
    ip_address = "10.24.239.10"
  }
}

firewallfirewall_route_ranges = {
  range1 = {
    ip_address = "10.23.253.177/32"
  }
  range2 = {
    ip_address = "10.23.253.178/32"
  }
  rang3 = {
    ip_address = "10.23.253.241/32"
  }
  range4 = {
    ip_address = "10.23.253.243/32"
  }
  range5 = {
    ip_address = "10.23.253.244/32"
  }
  range6 = {
    ip_address = "10.23.253.177/32"
  }
  range7 = {
    ip_address = "10.23.253.178/32"
  }
  range8 = {
    ip_address = "10.23.253.241/32"
  }
  range9 = {
    ip_address = "10.23.253.243/32"
  }
  range10 = {
    ip_address = "10.23.253.244/32"
  }  
  range11 = {
    ip_address = "10.63.111.175/32"
  }
  range12 = {
    ip_address = "10.63.111.187/32"
  }
  range13 = {
    ip_address = "10.63.111.176/32"
  }
  range14 = {
    ip_address = "10.63.111.188/32"
  }
  range15 = {
    ip_address =  "10.65.64.155/32"
  }
  range16 = {
    ip_address =  "10.65.64.180/32"
  }
  range17 = {
    ip_address = "10.65.64.156/32"
  }
  range18 = {
    ip_address = "10.65.64.181/32"
  }
  range19 = {
    ip_address = "10.100.197.200/32"
  }
  range20 = {
    ip_address =  "10.100.197.200/32"
  }
}

migration_linux_vms = {
  prddartsmigdb01 = {
    ip_address = "10.24.239.11"
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
