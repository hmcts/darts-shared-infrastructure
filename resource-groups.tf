resource "azurerm_resource_group" "darts_resource_group" {
  name     = format("%s-%s-rg", var.product, var.env)
  location = var.location

  tags = var.common_tags
}

resource "azurerm_resource_group" "darts_migration_resource_group" {
  count    = local.is_migration_environment ? 1 : 0
  name     = format("%s-migration-%s-rg", var.product, var.env)
  location = var.location

  tags = var.common_tags
}

moved {
  from = azurerm_resource_group.darts_migration_resource_group
  to   = azurerm_resource_group.darts_migration_resource_group[0]
}
