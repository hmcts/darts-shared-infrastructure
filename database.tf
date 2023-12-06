resource "azurerm_subnet" "postgres" {
  name                 = "postgres-sn"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[each.key].name
  virtual_network_name = azurerm_virtual_network.migration.name
  address_prefixes     = [var.postgres_subnet_address_space]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_key_vault_secret" "POSTGRES_USER" {
  name         = "POSTGRES-USER"
  value        = module.postgresql_flexible.username
  key_vault_id = module.darts_migration_key_vault.key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_PASS" {
  name         = "POSTGRES-PASS"
  value        = module.postgresql_flexible.password
  key_vault_id = module.darts_migration_key_vault.key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_HOST" {
  name         = "POSTGRES-HOST"
  value        = module.postgresql_flexible.fqdn
  key_vault_id = module.darts_migration_key_vault.key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_PORT" {
  name         = "POSTGRES-PORT"
  value        = local.db_port
  key_vault_id = module.darts_migration_key_vault.key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_DATABASE" {
  name         = "POSTGRES-DATABASE"
  value        = local.db_name
  key_vault_id = module.darts_migration_key_vault.key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

data "azurerm_subscription" "this" {}

module "postgresql_flexible" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  providers = {
    azurerm.postgres_network = azurerm
  }

  source              = "git@github.com:hmcts/terraform-module-postgresql-flexible?ref=master"
  env                 = var.env
  product             = var.product
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[each.key].name
  component           = var.component
  name                = "darts-migration"
  business_area       = "sds"
  location            = var.location
  pgsql_storage_mb    = 4194304
  pgsql_sku           = "GP_Standard_D8ds_v4"

  common_tags               = var.common_tags
  admin_user_object_id      = var.jenkins_AAD_objectId
  pgsql_delegated_subnet_id = "/subscriptions/${data.azurerm_subscription.this.subscription_id}/resourceGroups/${azurerm_resource_group.darts_migration_resource_group[each.key].name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.migration.name}/subnets/${azurerm_subnet.postgres.name}"
  pgsql_databases = [
    {
      name : local.db_name
    }
  ]

  pgsql_version = "15"
}
