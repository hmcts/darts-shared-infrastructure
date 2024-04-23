data "azurerm_client_config" "current" {}

module "darts_key_vault" {
  source = "git@github.com:hmcts/cnp-module-key-vault?ref=master"

  name                    = "darts-${var.env}"
  product                 = var.product
  env                     = var.env
  object_id               = var.jenkins_AAD_objectId
  resource_group_name     = azurerm_resource_group.darts_resource_group.name
  product_group_name      = "DTS Darts Modernisation"
  developers_group        = local.admin_group_map[var.env]
  create_managed_identity = true

  common_tags = var.common_tags
}

resource "azurerm_key_vault_secret" "MaxFileUploadSizeInMegabytes" {
  name         = "MaxFileUploadSizeInMegabytes"
  value        = var.max-file-upload-megabytes
  key_vault_id = module.darts_key_vault.key_vault_id
}

resource "azurerm_key_vault_secret" "MaxFileUploadRequestSizeInMegabytes" {
  name         = "MaxFileUploadRequestSizeInMegabytes"
  value        = var.max-file-upload-request-megabytes
  key_vault_id = module.darts_key_vault.key_vault_id
}

module "darts_migration_key_vault" {
  count  = local.is_migration_environment ? 1 : 0
  source = "git@github.com:hmcts/cnp-module-key-vault?ref=master"

  name                    = "darts-migration-${var.env}"
  product                 = var.product
  env                     = var.env
  object_id               = var.jenkins_AAD_objectId
  resource_group_name     = azurerm_resource_group.darts_migration_resource_group[0].name
  product_group_name      = "DTS Darts Modernisation"
  developers_group        = local.admin_group_map[var.env]
  create_managed_identity = false

  common_tags = var.common_tags
}

moved {
  from = module.darts_migration_key_vault
  to   = module.darts_migration_key_vault[0]
}

resource "random_string" "session-secret" {
  length = 16
}

resource "azurerm_key_vault_secret" "darts-portal-session-secret" {
  name         = "darts-portal-session-secret"
  value        = random_string.session-secret.result
  key_vault_id = module.darts_key_vault.key_vault_id
}