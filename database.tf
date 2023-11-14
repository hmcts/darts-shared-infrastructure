
data "azurerm_resource_group" "rg" {
  name = local.rg_name
}

resource "azurerm_subnet" "postgres" {
  name                 = "postgres-sn"
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.migration.name
  address_prefixes     = [var.address_space]
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



resource "azurerm_key_vault_secret" "POSTGRES-USER" {
  name         = "POSTGRES-USER"
  value        = module.postgresql_flexible.username
  key_vault_id = module.darts_migration_key_vault.key_vault_id
}

resource "azurerm_key_vault_secret" "POSTGRES-PASS" {
  name         = "POSTGRES-PASS"
  value        = module.postgresql_flexible.password
  key_vault_id = module.darts_migration_key_vault.key_vault_id
}

resource "azurerm_key_vault_secret" "POSTGRES_HOST" {
  name         = "POSTGRES-HOST"
  value        = module.postgresql_flexible.fqdn
  key_vault_id = module.darts_migration_key_vault.key_vault_id
}

resource "azurerm_key_vault_secret" "POSTGRES_PORT" {
  name         = "POSTGRES-PORT"
  value        = local.db_port
  key_vault_id = module.darts_migration_key_vault.key_vault_id
}

resource "azurerm_key_vault_secret" "POSTGRES_DATABASE" {
  name         = "POSTGRES-DATABASE"
  value        = local.db_name
  key_vault_id = module.darts_migration_key_vault.key_vault_id
}

module "postgresql_flexible" {
  providers = {
    azurerm.postgres_network = azurerm
  }

  source              = "git@github.com:hmcts/terraform-module-postgresql-flexible?ref=master"
  env                 = var.env
  product             = var.product
  resource_group_name = local.rg_name
  component           = var.component
  business_area       = "sds"
  location            = var.location
  pgsql_storage_mb    = 4194304
  pgsql_sku           = "GP_Standard_D8ds_v4"
  

  common_tags                        = var.common_tags
  admin_user_object_id           = var.jenkins_AAD_objectId
  pgsql_delegated_subnet_id = azurerm_subnet.postgres.id
  pgsql_databases = [
    {
      name : local.db_name
    }
  ]

  pgsql_version = "15"
}
