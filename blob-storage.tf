resource "azurerm_storage_account" "storage_account" {
  storage_account_name     =  replace("${var.product}${var.env}", "-", "")
  resource_group_name      = azurerm_resource_group.darts_resource_group.name
  location                 = "UK South"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"

  tags = var.common_tags
}

resource "azurerm_storage_container" "darts" {
  source                = "git@github.com:hmcts/cnp-module-storage-account?ref=master"
  name = var.storage_container_name
  resource_group_name   = azurerm_resource_group.darts_resource_group.name
  account_kind          = "StorageV2"
  env                   = "${var.env}"
  storage_account_name  = azurerm_storage_account.storage_account.storage_account_name
}

resource "azurerm_storage_blob" "outbound" {
  name                   = "${var.product}-outbound-blob-st-${var.env}"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.darts.name
  type                   = "Block"
}
resource "azurerm_storage_blob" "unstructured" {
  name                   = "${var.product}-unstrcutured-blob-st-${var.env}"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.darts.name
  type                   = "Block"
}
