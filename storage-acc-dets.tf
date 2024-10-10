data "azurerm_resource_group" "darts_resource_group" {
  name = format("%s-%s-rg", var.product, var.env)
}

data "azurerm_subnet" "private_endpoints" {
  resource_group_name  = local.private_endpoint_rg_name
  virtual_network_name = local.private_endpoint_vnet_name
  name                 = "private-endpoints"
}

module "sa_dets" {
  source = "git@github.com:hmcts/cnp-module-storage-account?ref=master"

  env = var.env

  storage_account_name = local.dets_storage_account_name
  common_tags          = var.common_tags

  default_action = "Allow"

  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  location            = var.location

  account_tier                    = var.sa_account_tier
  account_kind                    = var.sa_account_kind
  account_replication_type        = var.sa_account_replication_type
  access_tier                     = var.sa_access_tier
  allow_nested_items_to_be_public = "true"
  enable_change_feed              = true
  private_endpoint_subnet_id      = data.azurerm_subnet.private_endpoints.id

  enable_data_protection = true

  containers = local.containers

  cors_rules = [{
    allowed_headers    = ["*"]
    allowed_methods    = ["GET", "OPTIONS"]
    allowed_origins    = ["https://hmctsdartsb2csbox.b2clogin.com"]
    exposed_headers    = ["*"]
    max_age_in_seconds = 200
  }]

}

resource "azurerm_storage_blob" "dets" {
  name                   = "${var.product}-dets-blob-st-${var.env}"
  storage_account_name   = module.sa_dets.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"

  depends_on = [module.sa]
}

