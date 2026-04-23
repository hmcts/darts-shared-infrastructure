hub                             = "prod"
address_space                   = "10.24.239.0/28"
postgres_subnet_address_space   = "10.24.239.48/28"
extended_address_space          = "10.24.239.160/28"
logic_apps_address_space        = "10.24.239.176/29"
virtual_machine_admins          = ["675f1c23-3e46-4cf8-867b-747eb60fe89d", "d8b336b1-91fb-4fa6-bbe2-1f197c0d52c8", "14f9cf0e-8327-4f12-9d2c-f7e7eb05629d", "50132661-6997-484e-b0fd-5ec1052afabb", "e7ea2042-4ced-45dd-8ae3-e051c6551789", "1f9e0772-2158-4377-9515-f749044d3178", "1d52a6eb-aa62-4dff-a7ac-3d71bccb67fc"]
virtual_machine_users           = []
storage_account_contributor_ids = ["aee94636-8387-4a51-b5a7-a96e580a32d7"]
defender_enable                 = true
defender_scan                   = true
log_analytics_workspace_name    = "hmcts-prod"
log_analytics_workspace_rg      = "oms-automation"
log_analytics_subscription_id   = "8999dec3-0104-4a27-94ee-6588559729d1"

migration_vms = {
  prddartsassess = {
    ip_address     = "10.24.239.5"
    data_disk_size = "2000"
  }
}

migration_gitlab_vms = {
  prddartsgitlab = {
    ip_address = "10.24.239.169"
    subnet     = "migration-subnet-extended"
  }
}

sku_name = "Premium"
family   = "P"
capacity = "1"

install_azure_monitor = true

pgsql_storage_tier = "P80"
