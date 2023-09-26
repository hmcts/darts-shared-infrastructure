data "azurerm_client_config" "current" {}

module "darts_key_vault" {
  source = "git@github.com:hmcts/cnp-module-key-vault?ref=master"

  name                    = format("darts-%s", var.env)
  product                 = var.product
  env                     = var.env
  object_id               = var.jenkins_AAD_objectId
  resource_group_name     = azurerm_resource_group.darts_resource_group.name
  product_group_name      = "DTS Darts Modernisation"
  create_managed_identity = true

  common_tags = var.common_tags
}

module "darts_migration_key_vault" {
  source = "git@github.com:hmcts/cnp-module-key-vault?ref=master"

  depends_on = [module.darts_key_vault]

  name                        = format("darts-migration-%s", var.env)
  product                     = var.product
  env                         = var.env
  object_id                   = var.jenkins_AAD_objectId
  resource_group_name         = azurerm_resource_group.darts_migration_resource_group.name
  product_group_name          = "DTS Darts Modernisation"
  create_managed_identity     = false
  managed_identity_object_ids = module.darts_key_vault.managed_identity_objectid

  common_tags = var.common_tags
}
