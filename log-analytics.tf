resource "azurerm_log_analytics_workspace" "migration-analytics" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "darts-migration-analytics-workspace"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.common_tags
}
