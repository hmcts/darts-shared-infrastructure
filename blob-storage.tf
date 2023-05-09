locals {
  outbound                = "${var.product}-outbound-blob-st-${var.env}"
  unstructured            = "${var.product}-unstrcutured-blob-st-${var.env}"
}

resource "azurerm_storage_account" "storage_account" {
  name                = replace("${var.product}${var.env}", "-", "")
  resource_group_name     = azurerm_resource_group.darts_resource_group.name
  location                 = "UK South"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"
  allow_blob_public_access = true

  tags = var.common_tags
}

module "darts" {
  source                = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  resource_group_name   = azurerm_resource_group.darts_resource_group.name
  account_kind          = "StorageV2"
  env                   = "${var.env}"
#   storage_container_name = "darts"
#   name                  = "darts"
  storage_account_name  = azurerm_storage_account.storage_account.name
#   container_access_type = "container"
}


resource "azurerm_storage_blob" "outbound" {
  name                   = local.outboud
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = module.darts.storage_container_name
  type                   = "Block"
}
resource "azurerm_storage_blob" "unstructured" {
  name                   = local.unstructured
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = module.darts.storage_container_name
  type                   = "Block"
}
