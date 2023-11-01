data "azurerm_resource_group" "darts_migration_resource_group" {
  name     = format("%s-migration-%s-rg", var.product, var.env)
}

module "sa-migration" {
  source                   = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  env                      = var.env
  storage_account_name     = local.migration_storage_account_name
  resource_group_name      = azurerm_resource_group.darts_migration_resource_group.name
  location                 = var.location
  account_kind             = var.sa_account_kind 
  account_tier             = var.sa_mig_account_kind
  account_replication_type = var.sa_account_replication_type
  containers               = local.containers-mig
  private_endpoint_subnet_id = resource.azurerm_subnet.migration.id
  nfsv3_enabled             = var.nfsv3_enabled == true
  common_tags               = var.common_tags
}

resource "azurerm_storage_blob" "migration-st" {
  name                   = "${var.product}-migration-blob-st-${var.env}"
  storage_account_name   = local.migration_storage_account_name
  storage_container_name = local.darts_migration_container
  type                   = "Block"
}