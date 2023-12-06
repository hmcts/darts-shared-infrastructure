resource "azurerm_subnet" "postgres" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0
  name                 = "postgres-sn"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[each.key].name
  virtual_network_name = azurerm_virtual_network.migration[each.key].name
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
  count = contains(["stg", "prod"], var.env) ? 1 : 0
  name         = "POSTGRES-USER"
  value        = module.postgresql_flexible[0].username
  key_vault_id = module.darts_migration_key_vault[each.key].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_PASS" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0
  name         = "POSTGRES-PASS"
  value        = module.postgresql_flexible[0].password
  key_vault_id = module.darts_migration_key_vault[each.key].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_HOST" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0
  name         = "POSTGRES-HOST"
  value        = module.postgresql_flexible[0].fqdn
  key_vault_id = module.darts_migration_key_vault[each.key].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_PORT" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name         = "POSTGRES-PORT"
  value        = local.db_port
  key_vault_id = module.darts_migration_key_vault[each.key].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

resource "azurerm_key_vault_secret" "POSTGRES_DATABASE" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name         = "POSTGRES-DATABASE"
  value        = local.db_name
  key_vault_id = module.darts_migration_key_vault[each.key].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

data "azurerm_subscription" "this" {}

module "postgresql_flexible" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0
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
  pgsql_delegated_subnet_id = "/subscriptions/${data.azurerm_subscription.this.subscription_id}/resourceGroups/${azurerm_resource_group.darts_migration_resource_group[each.key].name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.migration[each.key].name}/subnets/${azurerm_subnet.postgres[each.key].name}"
  pgsql_databases = [
    {
      name : local.db_name
    }
  ]

  pgsql_version = "15"
}
