data "azurerm_resource_group" "darts_migration_resource_group" {
  name = format("%s-migration-%s-rg", var.product, var.env)
}

module "sa-migration" {
  for_each = contains(["stg", "prod"], var.env) ? 1 : {}
  source                            = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  env                               = var.env
  storage_account_name              = local.migration_storage_account_name
  resource_group_name               = azurerm_resource_group.darts_migration_resource_group.name
  location                          = var.location
  account_kind                      = var.sa_mig_account_kind
  account_tier                      = var.sa_mig_account_tier
  account_replication_type          = var.sa_mig_account_replication_type
  containers                        = local.containers-mig
  private_endpoint_subnet_id        = resource.azurerm_subnet.migration.id
  enable_nfs                        = true
  enable_hns                        = true
  enable_data_protection            = true
  enable_versioning                 = false
  defender_enabled                  = var.defender_enable
  defender_malware_scanning_enabled = var.defender_scan
  common_tags                       = var.common_tags
}

resource "azurerm_storage_blob" "migration-st" {
  for_each = contains(["stg", "prod"], var.env) ? 1 : {}
  name                   = "${var.product}-migration-blob-st-${var.env}"
  storage_account_name   = module.sa-migration.storageaccount_name
  storage_container_name = local.darts_migration_container
  type                   = "Block"

  depends_on = [module.sa-migration]
}
