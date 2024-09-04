resource "azurerm_log_analytics_workspace" "migration-analytics" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "darts-migration-analytics-workspace"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.common_tags
}

resource "azurerm_log_analytics_workspace" "postgres-analytics" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "darts-postgres-analytics-workspace"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name               = "example-postgres-diagnostics"
  target_resource_id = azurerm_postgresql_flexible_server.postgresql_flexible.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.postgres-analytics.id

  enabled_log {
    category = "AuditEvent"
  }
  enabled_log {
    category = "PostgreSQLLogs"
  }
  enabled_log {
    category = "PostgreSQLFlexSessions"
  }
  enabled_log {
    category = "PostgreSQLFlexQueryStoreRuntime"
  }
  enabled_log {
    category = "PostgreSQLFlexQueryStoreWaitStats"
  }
  enabled_log {
    category = "PostgreSQLFlexTableStats"
  }
  enabled_log {
    category = "PostgreSQLFlexDatabaseXacts"
  }
  metric {
    category = "AllMetrics"
  }
}