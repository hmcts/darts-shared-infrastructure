storage_account_contributor_ids = ["87c8cf3d-ff9d-4d8f-8430-ccc737764435"]
hub                             = "nonprod"
address_space                   = "10.24.239.128/28"
postgres_subnet_address_space   = "10.24.239.144/28"

modernisation_vms_test = {
  perftstwindarts = {
    ip_address = "10.24.239.140"
    sku        = "Standard_D4ds_v5"
  }
}
modernisation_linux_vms = {
  perftstlindarts = {
    ip_address = "10.24.239.138"
    sku        = "Standard_D4ds_v5"
  }
}