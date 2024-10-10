locals {
  vault_name           = "${var.product}-${var.env}"
  migration_vault_name = "${var.product}-migration-${var.env}"
  hub = {
    nonprod = {
      subscription = "fb084706-583f-4c9a-bdab-949aac66ba5c"
      ukSouth = {
        name        = "hmcts-hub-nonprodi"
        next_hop_ip = "10.11.72.36"
      }
    }
    sbox = {
      subscription = "ea3a8c1e-af9d-4108-bc86-a7e2d267f49c"
      ukSouth = {
        name        = "hmcts-hub-sbox-int"
        next_hop_ip = "10.10.200.36"
      }
    }
    prod = {
      subscription = "0978315c-75fe-4ada-9d11-1eb5e0e0b214"
      ukSouth = {
        name        = "hmcts-hub-prod-int"
        next_hop_ip = "10.11.8.36"
      }
    }
  }
  storage_account_name      = "${var.product}sa${var.env}"
  dets_storage_account_name = "dets_sa_${var.env}"

  containers = [{
    name        = "darts-outbound"
    access_type = "private"
    },
    {
      name        = "darts-unstructured"
      access_type = "private"
    },
    {
      name        = local.darts_inbound_container
      access_type = "private"
    },
    {
      name        = local.darts_container_name
      access_type = "container"
  }]
  containers-mig = [{
    name        = "darts-migration"
    access_type = "private"
  }]
  containers-dets = [{
    name        = "darts-dets-migration"
    access_type = "private"
  }]
  darts_container_name      = "darts-st-container"
  darts_inbound_container   = "darts-inbound-container"
  darts_migration_container = "darts-migration"
  db_name                   = "psql-${var.env}-dartsmig-01"
  db_name_dets              = "psql-${var.env}-detsmig-01"
  db_name_replica           = "psql-${var.env}-darts-replica"
  db_port                   = 5432

  palo_address_space = [for network in var.palo_networks : network.address_space]
  flattened_nsg_rules = flatten([
    for network_key, network in var.palo_networks : [
      for rule_key, rule in network.nsg_rules : {
        network_key = network_key
        rule_key    = rule_key
        rule        = rule
      }
    ]
  ])

  vnet_address_space = var.logic_apps_address_space != null && var.extended_address_space != null ? [var.address_space, var.postgres_subnet_address_space, var.extended_address_space, var.logic_apps_address_space] : [var.address_space, var.postgres_subnet_address_space]

  admin_group_map = {
    "demo" = "DTS Darts Admin (env:demo)"
    "ithc" = "DTS Darts Admin (env:ithc)"
    "test" = "DTS Darts Admin (env:test)"
    "stg"  = "DTS Darts Admin (env:staging)"
    "prod" = "DTS Darts Admin (env:production)"
  }

  private_endpoint_rg_name   = var.businessArea == "sds" ? "ss-${var.env}-network-rg" : "${var.businessArea}-${var.env}-network-rg"
  private_endpoint_vnet_name = var.businessArea == "sds" ? "ss-${var.env}-vnet" : "${var.businessArea}-${var.env}-vnet"


  migration_environments    = ["stg", "prod"]
  is_migration_environment  = contains(local.migration_environments, var.env)
  production_environments   = ["prod"]
  is_production_environment = contains(local.production_environments, var.env)
  test_environments         = ["test", "demo", "stg"]
  is_test_environment       = contains(local.test_environments, var.env)
}

data "azurerm_key_vault_secret" "aadds_username" {
  name         = "domain-join-username"
  key_vault_id = "/subscriptions/17390ec1-5a5e-4a20-afb3-38d8d726ae45/resourceGroups/PINT-RG/providers/Microsoft.KeyVault/vaults/hmcts-kv-prod-int"
}

data "azurerm_key_vault_secret" "aadds_password" {
  name         = "domain-join-password"
  key_vault_id = "/subscriptions/17390ec1-5a5e-4a20-afb3-38d8d726ae45/resourceGroups/PINT-RG/providers/Microsoft.KeyVault/vaults/hmcts-kv-prod-int"
}

