

data "azurerm_subnet" "private_endpoints_dets_sa" {
  resource_group_name  = local.private_endpoint_rg_name
  virtual_network_name = local.private_endpoint_vnet_name
  name                 = "private-endpoints"
}

module "sa_dets" {
  source                            = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  env                               = var.env
  storage_account_name              = local.dets_storage_account_name
  common_tags                       = var.common_tags
  resource_group_name               = azurerm_resource_group.darts_migration_resource_group[0].name
  location                          = var.location
  account_tier                      = var.sa_account_tier
  account_kind                      = var.sa_account_kind
  account_replication_type          = var.sa_account_replication_type
  access_tier                       = var.sa_access_tier
  allow_nested_items_to_be_public   = "true"
  enable_change_feed                = true
  private_endpoint_subnet_id        = data.azurerm_subnet.private_endpoints_dets_sa.id
  defender_enabled                  = var.defender_enable
  defender_malware_scanning_enabled = var.defender_scan
  enable_data_protection            = true
  containers                        = local.containers-dets
  enable_versioning                 = false
  enable_sftp                       = var.enable_sftp
}

# resource "azurerm_storage_blob" "dets" {
#   name                   = "${var.product}-dets-blob-st-${var.env}"
#   storage_account_name   = module.sa_dets.storageaccount_name
#   storage_container_name = local.dets_container_name
#   type                   = "Block"

#   depends_on = [module.sa_dets]
# }

