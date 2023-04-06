resource "azurerm_resource_group" "darts_resource_group" {
  name     = format("%s-%s-rg", var.product, var.env)
  location = var.location

  tags = var.common_tags
}
