resource "azurerm_logic_app_workflow" "migration_scan" {
  name                = "migration-logic-app"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name

}



