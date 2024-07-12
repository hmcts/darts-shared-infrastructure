
module "sa-migration-standard" {
  count                                      = local.is_migration_environment ? 1 : 0
  source                                     = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  env                                        = var.env
  storage_account_name                       = "sa${var.env}${var.product}mig02"
  resource_group_name                        = azurerm_resource_group.darts_migration_resource_group[0].name
  location                                   = var.location
  account_kind                               = "StorageV2"
  account_tier                               = "Standard"
  account_replication_type                   = "ZRS"
  containers                                 = local.containers-mig
  private_endpoint_subnet_id                 = resource.azurerm_subnet.migration[0].id
  enable_nfs                                 = true
  enable_hns                                 = true
  enable_data_protection                     = true
  enable_versioning                          = false
  defender_enabled                           = var.defender_enable
  defender_malware_scanning_enabled          = var.defender_scan
  defender_malware_scanning_cap_gb_per_month = 250000
  common_tags                                = var.common_tags
}

moved {
  from = module.sa-migration
  to   = module.sa-migration[0]
}

resource "azurerm_storage_blob" "migration-st" {
  count                  = local.is_migration_environment ? 1 : 0
  name                   = "${var.product}-migration-blob-st-${var.env}"
  storage_account_name   = module.sa-migration-standard[0].storageaccount_name
  storage_container_name = local.darts_migration_container
  type                   = "Block"
}

data "azurerm_subnet" "private_endpoints_dets" {
  resource_group_name  = local.private_endpoint_rg_name
  virtual_network_name = local.private_endpoint_vnet_name
  name                 = "private-endpoints"
}

module "sa-dets-standard" {
  count                                      = local.is_test_environment ? 1 : 0
  source                                     = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  env                                        = var.env
  storage_account_name                       = "${var.env}dets${var.product}"
  resource_group_name                        = azurerm_resource_group.darts_resource_group.name
  location                                   = var.location
  account_kind                               = "StorageV2"
  account_tier                               = "Standard"
  account_replication_type                   = "ZRS"
  containers                                 = local.containers-mig
  private_endpoint_subnet_id                 = data.azurerm_subnet.private_endpoints_dets.id
  enable_nfs                                 = true
  enable_hns                                 = true
  enable_data_protection                     = true
  enable_versioning                          = false
  defender_enabled                           = var.defender_enable
  defender_malware_scanning_enabled          = var.defender_scan
  defender_malware_scanning_cap_gb_per_month = 250000
  common_tags                                = var.common_tags
}

resource "azurerm_storage_blob" "dets-st" {
  count                  = local.is_test_environment ? 1 : 0
  name                   = "${var.product}-dets-blob-st-${var.env}"
  storage_account_name   = module.sa-dets-standard[0].storageaccount_name
  storage_container_name = local.darts_migration_container
  type                   = "Block"
}

module "sa-dets-standard2" {
  source                                     = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  env                                        = var.env
  storage_account_name                       = "${var.env}dets${var.product}"
  resource_group_name                        = azurerm_resource_group.darts_resource_group.name
  location                                   = var.location
  account_kind                               = "StorageV2"
  account_tier                               = "Standard"
  account_replication_type                   = "ZRS"
  containers                                 = local.containers-mig
  private_endpoint_subnet_id                 = data.azurerm_subnet.private_endpoints_dets.id
  enable_nfs                                 = true
  enable_hns                                 = true
  enable_data_protection                     = true
  enable_versioning                          = false
  defender_enabled                           = var.defender_enable
  defender_malware_scanning_enabled          = var.defender_scan
  defender_malware_scanning_cap_gb_per_month = 250000
  common_tags                                = var.common_tags
}

resource "azurerm_storage_blob" "dets-st2" {
  name                   = "${var.product}-dets-blob-st-${var.env}"
  storage_account_name   = module.sa-dets-standard.storageaccount_name
  storage_container_name = local.darts_migration_container
  type                   = "Block"
}
