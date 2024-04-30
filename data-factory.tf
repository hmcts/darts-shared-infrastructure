module "datafactory" {

  count = local.is_migration_environment ? 1 : 0

  source = "git@github.com:hmcts/terraform-module-azure-datafactory?ref=main"
  
  env    = var.env
  product   = var.product
  component = var.component
  location = var.location
  common_tags = var.common_tags

  existing_resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
}