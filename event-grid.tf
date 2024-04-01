resource "azurerm_eventgrid_topic" "av-scanner" {
  name                = "av-scanner-output"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
}


resource "azurerm_eventgrid_topic" "example" {
  name                = "av-scan-output"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  location            = azurerm_resource_group.darts_migration_resource_group[0].location

  tags = {
    environment = "sample"
  }
}