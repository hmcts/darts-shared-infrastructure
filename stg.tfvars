hub                             = "prod"
address_space                   = "10.24.239.128/28"
postgres_subnet_address_space   = "10.24.239.144/28"
virtual_machine_admins          = ["675f1c23-3e46-4cf8-867b-747eb60fe89d", "d8b336b1-91fb-4fa6-bbe2-1f197c0d52c8", "14f9cf0e-8327-4f12-9d2c-f7e7eb05629d", "50132661-6997-484e-b0fd-5ec1052afabb", "d51b8769-b737-4706-abd2-23d33b38b8c0"]
storage_account_contributor_ids = ["87c8cf3d-ff9d-4d8f-8430-ccc737764435", "4908856e-c987-4ad8-b519-a5480a1fcc12"]
log_analytics_workspace_name    = "hmcts-nonprod"
log_analytics_workspace_rg      = "oms-automation"
log_analytics_subscription_id   = "1c4f0704-a29e-403d-b719-b90c34ef14c9"
sku_name                        = "Premium"
family                          = "P"
capacity                        = "1"

modernisation_vms = {
  stgdartsmidmock = {
    ip_address = "10.24.239.142"
    sku        = "Standard_D4ds_v5"
  }
}

install_azure_monitor = true
enable_sftp           = true
