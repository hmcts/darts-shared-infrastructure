provider "azurerm" {
  subscription_id = var.log_analytics_subscription_id
  alias           = "log-analytics-quarantine"
  features {}
}

resource "azurerm_log_analytics_workspace" "quarantine-analytics" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "darts-quarantine-analytics-workspace"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  sku                 = "PerGB2018"
  retention_in_days   = 730
  tags                = var.common_tags
}


data "azurerm_log_analytics_workspace" "quarantine" {
  provider            = azurerm.log-analytics-subscription
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_workspace_rg
}

resource "azurerm_monitor_diagnostic_setting" "quarantine-diagnostic" {
  count                      = local.is_production_environment ? 1 : 0
  name                       = "storage-diagnostics"
  target_resource_id         = module.sa-migration-quarantine[0].storageaccount_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.quarantine-analytics[0].id

  # All metrics
  metric {
    category = "Capacity"
    enabled  = true
  }
  metric {
    category = "Transaction"
    enabled  = true
  }
}
resource "azurerm_monitor_diagnostic_setting" "storageaccount_diagnostic_blobs" {
  count                      = local.is_production_environment ? 1 : 0
  name                       = "storage-blob-quarantine"
  target_resource_id         = "${module.sa-migration-quarantine[0].storageaccount_id}/blobServices/default/"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.quarantine-analytics[0].id


  enabled_log {
    category_group = "allLogs"
  }

  # All metrics
  metric {
    category = "Capacity"
    enabled  = true
  }
  metric {
    category = "Transaction"
    enabled  = true
  }
}