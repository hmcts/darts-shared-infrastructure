resource "azurerm_service_plan" "logic" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "darts-migration-app-service-plan-${var.env}"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  os_type             = "Linux"
  sku_name            = "WS1"
  tags                = var.common_tags
}

resource "azurerm_storage_account" "logic" {
  count                     = local.is_migration_environment ? 1 : 0
  name                      = "sadartslogic${var.env}"
  resource_group_name       = azurerm_resource_group.darts_migration_resource_group[0].name
  location                  = azurerm_resource_group.darts_migration_resource_group[0].location
  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  tags                      = var.common_tags
}

resource "azurerm_storage_account_network_rules" "logic" {
  count              = local.is_migration_environment ? 1 : 0
  storage_account_id = azurerm_storage_account.logic[0].id
  depends_on         = [azurerm_logic_app_standard.logic]

  default_action             = "Deny"
  ip_rules                   = []
  virtual_network_subnet_ids = [azurerm_subnet.migration[0].id, azurerm_subnet.migration-extended[0].id]
  bypass                     = ["AzureServices"]
}

resource "azurerm_private_endpoint" "logic" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "sadartslogic${var.env}-pe"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  subnet_id           = azurerm_subnet.migration-extended[0].id
  tags                = var.common_tags

  private_service_connection {
    name                           = azurerm_storage_account.logic[0].name
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.logic[0].id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "endpoint-dnszonegroup"
    private_dns_zone_ids = ["/subscriptions/1baf5470-1c3e-40d3-a6f7-74bfbce4b348/resourceGroups/core-infra-intsvc-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"]
  }
}

resource "azurerm_logic_app_standard" "logic" {
  count                      = local.is_migration_environment ? 1 : 0
  name                       = "darts-migration-logic-${var.env}"
  resource_group_name        = azurerm_resource_group.darts_migration_resource_group[0].name
  location                   = azurerm_resource_group.darts_migration_resource_group[0].location
  app_service_plan_id        = azurerm_service_plan.logic[0].id
  storage_account_name       = azurerm_storage_account.logic[0].name
  storage_account_access_key = azurerm_storage_account.logic[0].primary_access_key
  version                    = "~4"
  tags                       = var.common_tags

  virtual_network_subnet_id = azurerm_subnet.migration-extended[0].id

  identity {
    type = "SystemAssigned"
  }

  app_settings = {}
}

