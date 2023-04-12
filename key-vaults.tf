data "azurerm_client_config" "current" {}

module "darts_key_vault" {
  source = "git@github.com:hmcts/cnp-module-key-vault?ref=master"

  name                    = format("darts-%s-kv", var.env)
  product                 = var.product
  env                     = var.env
  object_id               = var.jenkins_AAD_objectId
  resource_group_name     = azurerm_resource_group.darts_resource_group.name
  product_group_name      = "DTS Platform Operations"
  create_managed_identity = true

  common_tags = var.common_tags
}

resource "azurerm_key_vault_secret" "darts_app_secret" {
  name         = format("darts-%s-app-secret", var.env)
  value        = azuread_application_password.secret.value
  key_vault_id = module.darts_key_vault.key_vault_id
}

resource "azurerm_key_vault_secret" "darts_app_id" {
  name         = format("darts-%s-app-id", var.env)
  value        = azuread_application.app.application_id
  key_vault_id = module.darts_key_vault.key_vault_id
}

resource "azurerm_key_vault_secret" "darts_tenant_id" {
  name         = format("darts-%s-tenant-id", var.env)
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = module.darts_key_vault.key_vault_id
}
