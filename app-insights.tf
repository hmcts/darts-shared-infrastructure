resource "azurerm_application_insights" "appinsights" {
  name                = "${var.product}-${var.env}"
  location            = azurerm_resource_group.darts_resource_group.location
  resource_group_name = azurerm_resource_group.darts_resource_group.name
  application_type    = "web"
  tags                = var.common_tags

  lifecycle {
    ignore_changes = [
      # Ignore changes to appinsights as otherwise upgrading to the Azure provider 2.x
      # destroys and re-creates this appinsights instance
      application_type,
    ]
  }
}

resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "AppInsightsConnectionString"
  value        = azurerm_application_insights.appinsights.connection_string
  key_vault_id = module.darts_key_vault.key_vault_id
}

resource "azurerm_key_vault_secret" "azure_appinsights_key" {
  name         = "AppInsightsInstrumentationKey"
  value        = azurerm_application_insights.appinsights.instrumentation_key
  key_vault_id = module.darts_key_vault.key_vault_id
}