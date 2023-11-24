hub                             = "prod"
address_space                   = "10.24.239.0/28"
postgres_subnet_address_space   = "10.24.239.192/28"
virtual_machine_admins          = ["675f1c23-3e46-4cf8-867b-747eb60fe89d", "d8b336b1-91fb-4fa6-bbe2-1f197c0d52c8", "14f9cf0e-8327-4f12-9d2c-f7e7eb05629d", "50132661-6997-484e-b0fd-5ec1052afabb", "e7ea2042-4ced-45dd-8ae3-e051c6551789"]
virtual_machine_users           = []
storage_account_contributor_ids = []
defender_enable                 = true
defender_scan                   = true

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
    address_space      = "10.24.239.48/28"
    public_ip_required = true
    nsg_deny_inbound   = true
  }
  trust = {
    address_space        = "10.24.239.16/28"
    enable_ip_forwarding = true
  }
  untrust = {
    address_space        = "10.24.239.32/28"
    enable_ip_forwarding = true
  }
}
