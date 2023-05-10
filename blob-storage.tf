locals {
  
  containers = [{
    name        = "darts"
    access_type = "private"
    }
  ]

}

resource "azurerm_storage_account" "storage_account" {
  storage_account_name     =  replace("${var.product}${var.env}", "-", "")
  resource_group_name      = azurerm_resource_group.darts_resource_group.name
  location                 = "UK South"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  account_kind             = "StorageV2"

  tags = var.common_tags
}

module "darts" {
  source = "git@github.com:hmcts/cnp-module-storage-account?ref=master"

  env = var.env

  storage_account_name = azurerm_storage_account.storage_account_name
  common_tags          = var.common_tags

  default_action = "Allow"

  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  account_tier                    = var.sa_account_tier
  account_kind                    = var.sa_account_kind
  account_replication_type        = var.sa_account_replication_type
  access_tier                     = var.sa_access_tier
  allow_nested_items_to_be_public = "true"

  enable_data_protection = true

  containers = local.containers
}


resource "azurerm_storage_blob" "outbound" {
  name                   = "${var.product}-outbound-blob-st-${var.env}"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = locals.containers.name
  type                   = "Block"
}
resource "azurerm_storage_blob" "unstructured" {
  name                   = "${var.product}-unstrcutured-blob-st-${var.env}"
  storage_account_name   = azurerm_storage_account.storage_account.name
  storage_container_name = locals.containers.name
  type                   = "Block"
}
