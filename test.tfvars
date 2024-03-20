storage_account_contributor_ids = ["87c8cf3d-ff9d-4d8f-8430-ccc737764435"]
hub                             = "prod"
address_space                   = "10.24.239.128/28"
postgres_subnet_address_space   = "10.24.239.144/28"

modernisation_vms = {
  perftstwindarts = {
    ip_address = "10.24.239.144"
    sku        = "Standard_D4ds_v5"
  }
}
modernisation_linux_vms = {
  perftstlindarts = {
    ip_address = "10.24.239.146"
    sku        = "Standard_D4ds_v5"
  }
}