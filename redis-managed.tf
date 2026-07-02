locals {
  managed_redis_environments = ["demo", "ithc", "test", "stg"]
  managed_redis_enabled_envs = contains(local.managed_redis_environments, var.env) ? toset([var.env]) : toset([])

  managed_redis_vnet_rg_name = "ss-${var.env}-network-rg"
  managed_redis_vnet_name    = "ss-${var.env}-vnet"
  managed_redis_subnet_name  = "iaas"
}

data "azurerm_subnet" "redis_private_endpoint" {
  for_each             = local.managed_redis_enabled_envs
  name                 = local.managed_redis_subnet_name
  resource_group_name  = local.managed_redis_vnet_rg_name
  virtual_network_name = local.managed_redis_vnet_name
}

module "managed_redis" {
  for_each = local.managed_redis_enabled_envs

  source = "git@github.com:hmcts/terraform-module-azure-managed-redis?ref=main"

  product     = var.product
  component   = "portal"
  env         = var.env
  location    = var.location
  common_tags = var.common_tags

  sku_name = "Balanced_B0"

  public_network_access   = "Disabled"
  create_private_endpoint = true
  subnet_id               = data.azurerm_subnet.redis_private_endpoint[each.key].id

  private_dns_zone_ids = [
    "/subscriptions/${var.private_dns_subscription_id}/resourceGroups/core-infra-intsvc-rg/providers/Microsoft.Network/privateDnsZones/privatelink.redis.azure.net"
  ]

  access_keys_authentication_enabled = true

  persistence_rdb_backup_frequency = "6h"
}

resource "azurerm_key_vault_secret" "managed_redis" {
  for_each     = module.managed_redis
  name         = "managed-redis-connection-string"
  value        = "rediss://:${urlencode(each.value.primary_access_key)}@${each.value.hostname}:${each.value.port}?tls=true"
  key_vault_id = module.darts_key_vault.key_vault_id
}
