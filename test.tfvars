storage_account_contributor_ids = ["87c8cf3d-ff9d-4d8f-8430-ccc737764435"]
hub                             = "nonprod"
address_space                   = "10.24.239.128/28"
postgres_subnet_address_space   = "10.24.239.144/28"
vm_subnet_id                    = "/subscriptions/3eec5bde-7feb-4566-bfb6-805df6e10b90/resourceGroups/ss-test-network-rg/providers/Microsoft.Network/virtualNetworks/ss-test-vnet/subnets/iaas"
log_analytics_workspace_name    = "hmcts-nonprod"
log_analytics_workspace_rg      = "oms-automation"
log_analytics_subscription_id   = "1c4f0704-a29e-403d-b719-b90c34ef14c9"
sku_name                        = "Premium"
family                          = "P"
capacity                        = "1"

modernisation_vms_test = {
  perftstwindarts = {
    sku = "Standard_D8ds_v5"
  }
}
modernisation_linux_vms = {
  perftstlindarts = {
    sku = "Standard_D4ds_v5"
  }
}

install_azure_monitor = true
enable_sftp           = true
