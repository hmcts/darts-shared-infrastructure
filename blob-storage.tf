locals {
  storage_account_name = "${var.product}sa${var.env}"
  containers = [{
    name        = "darts-outbound"
    access_type = "private"
    },
    {
      name        = "darts-unstructured"
      access_type = "private"
  },
    {
      name        = local.darts_container_name
      access_type = "container"
  }]
  darts_container_name = "darts-st-container"
}

data "azurerm_resource_group" "darts_resource_group" {
    name     = format("%s-%s-rg", var.product, var.env)
}



module "sa" {
  source = "git@github.com:hmcts/cnp-module-storage-account?ref=master"

  env = var.env

  storage_account_name = local.storage_account_name
  common_tags          = var.common_tags

  default_action = "Allow"

  resource_group_name = azurerm_resource_group.darts_resource_group.name
  location            = var.location

  account_tier                    = var.sa_account_tier
  account_kind                    = var.sa_account_kind
  account_replication_type        = var.sa_account_replication_type
  access_tier                     = var.sa_access_tier
  allow_nested_items_to_be_public = "true"
  
  enable_data_protection = true

  containers = local.containers

    dynamic "blob_properties" {
      for_each = var.enable_data_protection == true ? [1] : []
      content {
        versioning_enabled  = true
        change_feed_enabled = var.enable_change_feed

        container_delete_retention_policy {
          days = 7
        }
        delete_retention_policy {
          days = 365
        }
        restore_policy {
          days = var.restore_policy_days
        }
        dynamic "cors_rule" {
          for_each = var.cors_rules

          content {
            allowed_headers    = cors_rule.value["allowed_headers"]
            allowed_methods    = cors_rule.value["allowed_methods"]
            allowed_origins    = cors_rule.value["allowed_origins"]
            exposed_headers    = cors_rule.value["exposed_headers"]
            max_age_in_seconds = cors_rule.value["max_age_in_seconds"]
          }
        }
      }
    }
}

resource "azurerm_storage_blob" "outbound" {
  name                   = "${var.product}-outbound-blob-st-${var.env}"
  storage_account_name   = local.storage_account_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
}
resource "azurerm_storage_blob" "unstructured" {
  name                   = "${var.product}-unstrcutured-blob-st-${var.env}"
  storage_account_name   = local.storage_account_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
}
resource "azurerm_storage_blob" "inbound" {
  name                   = "${var.product}-inbound-blob-st-${var.env}"
  storage_account_name   = local.storage_account_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
}
