hub                             = "prod"
address_space                   = "10.24.239.64/28"
virtual_machine_admins          = ["675f1c23-3e46-4cf8-867b-747eb60fe89d", "d8b336b1-91fb-4fa6-bbe2-1f197c0d52c8", "14f9cf0e-8327-4f12-9d2c-f7e7eb05629d", "50132661-6997-484e-b0fd-5ec1052afabb", "e7ea2042-4ced-45dd-8ae3-e051c6551789", "cd395cb0-35d7-454b-8c99-26422f78901e"]
virtual_machine_users           = []
firewall_address_space          = "10.24.239.192/26"
storage_account_contributor_ids = ["87c8cf3d-ff9d-4d8f-8430-ccc737764435"]

firewall_network_rules = {
  darts-migration-stg = {
    action   = "Allow"
    priority = 300
    rules = {
      "App Outbound" = {
        protocols             = ["TCP"]
        source_addresses      = ["10.23.253.177/32", "10.23.253.178/32"]
        destination_addresses = ["10.24.239.64/28"]
        destination_ports     = ["22", "1521"]
      }
      "App Inbound" = {
        protocols             = ["TCP"]
        source_addresses      = ["10.24.239.64/28"]
        destination_addresses = ["10.23.253.177/32", "10.23.253.178/32"]
        destination_ports     = ["22", "1521"]
      }
      "DARTS Centerra Outbound" = {
        protocols             = ["TCP", "UDP"]
        source_addresses      = ["10.23.253.241/32", "10.23.253.242/32", "10.23.253.243/32", "10.23.253.244/32"]
        destination_addresses = ["10.24.239.64/28"]
        destination_ports     = ["3218", "3682"]
      }
      "DARTS Centerra Inbound" = {
        protocols             = ["TCP", "UDP"]
        source_addresses      = ["10.24.239.64/28"]
        destination_addresses = ["10.23.253.241/32", "10.23.253.242/32", "10.23.253.243/32", "10.23.253.244/32"]
        destination_ports     = ["3218", "3682"]
      }
    }
  }
}

firewall_nat_rules = {
  darts-migration-dnat-stg = {
    priority = 100
    action   = "Dnat"
    rules = {
      "CN0052-Node1-A-DNAT-3218" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.63.111.175"]
        destination_ports  = ["3218"]
        translated_address = "10.23.253.241"
        translated_port    = "3218"
      }
      "CN0052-Node1-A-DNAT-3682" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.63.111.175"]
        destination_ports  = ["3682"]
        translated_address = "10.23.253.241"
        translated_port    = "3682"
      }
      "CN0052-Node1-B-DNAT-3218" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.63.111.187"]
        destination_ports  = ["3218"]
        translated_address = "10.23.253.241"
        translated_port    = "3218"
      }
      "CN0052-Node1-B-DNAT-3682" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.63.111.187"]
        destination_ports  = ["3682"]
        translated_address = "10.23.253.241"
        translated_port    = "3682"
      }
      "CN0052-Node2-A-DNAT-3218" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.63.111.176"]
        destination_ports  = ["3218"]
        translated_address = "10.23.253.242"
        translated_port    = "3218"
      }
      "CN0052-Node2-A-DNAT-3682" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.63.111.176"]
        destination_ports  = ["3682"]
        translated_address = "10.23.253.242"
        translated_port    = "3682"
      }
      "CN0052-Node2-B-DNAT-3218" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.63.111.188"]
        destination_ports  = ["3218"]
        translated_address = "10.23.253.242"
        translated_port    = "3218"
      }
      "CN0052-Node2-B-DNAT-3682" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.63.111.188"]
        destination_ports  = ["3682"]
        translated_address = "10.23.253.242"
        translated_port    = "3682"
      }
      "CN0052-Node3-A-DNAT-3218" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.65.64.155"]
        destination_ports  = ["3218"]
        translated_address = "10.23.253.243"
        translated_port    = "3218"
      }
      "CN0052-Node3-A-DNAT-3682" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.65.64.155"]
        destination_ports  = ["3682"]
        translated_address = "10.23.253.243"
        translated_port    = "3682"
      }
      "CN0052-Node3-B-DNAT-3218" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.65.64.180"]
        destination_ports  = ["3218"]
        translated_address = "10.23.253.243"
        translated_port    = "3218"
      }
      "CN0052-Node3-B-DNAT-3682" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.65.64.180"]
        destination_ports  = ["3682"]
        translated_address = "10.23.253.243"
        translated_port    = "3682"
      }
      "CN0052-Node4-A-DNAT-3218" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.65.64.156"]
        destination_ports  = ["3218"]
        translated_address = "10.23.253.244"
        translated_port    = "3218"
      }
      "CN0052-Node4-A-DNAT-3682" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.65.64.156"]
        destination_ports  = ["3682"]
        translated_address = "10.23.253.244"
        translated_port    = "3682"
      }
      "CN0052-Node4-B-DNAT-3218" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.65.64.181"]
        destination_ports  = ["3218"]
        translated_address = "10.23.253.244"
        translated_port    = "3218"
      }
      "CN0052-Node4-B-DNAT-3682" = {
        protocols          = ["TCP", "UDP"]
        source_addresses   = ["10.65.64.181"]
        destination_ports  = ["3682"]
        translated_address = "10.23.253.244"
        translated_port    = "3682"
      }
    }
  }
}

firewall_log_analytics_enabled = true

migration_vms = {}

sku_name = "Premium"
family   = "P"
capacity = "1"

palo_networks = {}
az_firewall_route_ranges = []
