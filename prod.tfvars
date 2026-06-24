hub                             = "prod"
address_space                   = "10.24.239.0/28"
postgres_subnet_address_space   = "10.24.239.48/28"
extended_address_space          = "10.24.239.160/28"
logic_apps_address_space        = "10.24.239.176/29"
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

pgsql_storage_tier   = "P80"
daily_data_cap_in_gb = 100
