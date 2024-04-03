# resource "azurerm_eventgrid_topic" "mig-scanner" {
#   count               = local.is_migration_environment ? 1 : 0
#   name                = "mig-scanner"
#   resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
#   location            = azurerm_resource_group.darts_migration_resource_group[0].location
# }


# resource "azurerm_eventgrid_topic" "mig-scan-topic" {
#   count               = local.is_migration_environment ? 1 : 0
#   name                = "mig-scan-output"
#   resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
#   location            = azurerm_resource_group.darts_migration_resource_group[0].location
# }