resource "azurerm_subnet" "postgres" {
  count                = local.is_migration_environment ? 1 : 0
  name                 = "postgres-sn"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  virtual_network_name = azurerm_virtual_network.migration[0].name
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

moved {
  from = azurerm_subnet.postgres
  to   = azurerm_subnet.postgres[0]
}

resource "azurerm_key_vault_secret" "POSTGRES_USER" {
  count        = local.is_migration_environment ? 1 : 0
  name         = "POSTGRES-USER"
  value        = module.postgresql_flexible[0].username
  key_vault_id = module.darts_migration_key_vault[0].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

moved {
  from = azurerm_key_vault_secret.POSTGRES_USER
  to   = azurerm_key_vault_secret.POSTGRES_USER[0]
}

resource "azurerm_key_vault_secret" "POSTGRES_PASS" {
  count        = local.is_migration_environment ? 1 : 0
  name         = "POSTGRES-PASS"
  value        = module.postgresql_flexible[0].password
  key_vault_id = module.darts_migration_key_vault[0].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

moved {
  from = azurerm_key_vault_secret.POSTGRES_PASS
  to   = azurerm_key_vault_secret.POSTGRES_PASS[0]
}

resource "azurerm_key_vault_secret" "POSTGRES_HOST" {
  count        = local.is_migration_environment ? 1 : 0
  name         = "POSTGRES-HOST"
  value        = module.postgresql_flexible[0].fqdn
  key_vault_id = module.darts_migration_key_vault[0].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

moved {
  from = azurerm_key_vault_secret.POSTGRES_HOST
  to   = azurerm_key_vault_secret.POSTGRES_HOST[0]
}

resource "azurerm_key_vault_secret" "POSTGRES_PORT" {
  count        = local.is_migration_environment ? 1 : 0
  name         = "POSTGRES-PORT"
  value        = local.db_port
  key_vault_id = module.darts_migration_key_vault[0].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

moved {
  from = azurerm_key_vault_secret.POSTGRES_PORT
  to   = azurerm_key_vault_secret.POSTGRES_PORT[0]
}

resource "azurerm_key_vault_secret" "POSTGRES_DATABASE" {
  count        = local.is_migration_environment ? 1 : 0
  name         = "POSTGRES-DATABASE"
  value        = local.db_name
  key_vault_id = module.darts_migration_key_vault[0].key_vault_id
  depends_on   = [module.darts_migration_key_vault]
}

moved {
  from = azurerm_key_vault_secret.POSTGRES_DATABASE
  to   = azurerm_key_vault_secret.POSTGRES_DATABASE[0]
}

data "azurerm_subscription" "this" {}

module "postgresql_flexible" {
  count = local.is_migration_environment ? 1 : 0
  providers = {
    azurerm.postgres_network = azurerm
  }

  source  = "git@github.com:hmcts/terraform-module-postgresql-flexible?ref=master"
  env     = var.env
  product = var.product

  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  component           = var.component
  name                = "darts-migration"
  business_area       = "sds"
  location            = var.location
  pgsql_storage_mb    = 8388608
  pgsql_sku           = "GP_Standard_D16ds_v4"

  common_tags               = var.common_tags
  admin_user_object_id      = var.jenkins_AAD_objectId
  pgsql_delegated_subnet_id = "/subscriptions/${data.azurerm_subscription.this.subscription_id}/resourceGroups/${azurerm_resource_group.darts_migration_resource_group[0].name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.migration[0].name}/subnets/${azurerm_subnet.postgres[0].name}"
  pgsql_databases = [
    {
      name : local.db_name
    },
    {
      name : local.db_name_dets
    },
    {
      name : local.db_name_replica
    }
  ]
  pgsql_server_configuration = [
    {
      name  = "azure.enable_temp_tablespaces_on_local_ssd"
      value = "off"
    },
    {
      name  = "backslash_quote"
      value = "on"
    }
  ]

  pgsql_version = "15"
}

moved {
  from = module.postgresql_flexible
  to   = module.postgresql_flexible[0]
}
