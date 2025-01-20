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


data "azurerm_log_analytics_workspace" "hmcts" {
  provider            = azurerm.log-analytics-subscription
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_workspace_rg
}

