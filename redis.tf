module "darts_redis" {
  source                        = "git@github.com:hmcts/cnp-module-redis?ref=fix%2Fadd-null-default"
  product                       = var.product
  location                      = azurerm_resource_group.darts_resource_group.location
  env                           = var.env
  common_tags                   = var.common_tags
  redis_version                 = "6"
  business_area                 = "sds"
  private_endpoint_enabled      = true
  public_network_access_enabled = false
  sku_name                      = var.sku_name
  family                        = var.family
  capacity                      = var.capacity
  resource_group_name           = azurerm_resource_group.darts_resource_group.name
}

moved {
  from = module.darts_redis[0]
  to   = module.darts_redis
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"
  value        = "rediss://:${urlencode(module.darts_redis.access_key)}@${module.darts_redis.host_name}:${module.darts_redis.redis_port}?tls=true"
  key_vault_id = module.darts_key_vault.key_vault_id
}

moved {
  from = azurerm_key_vault_secret.redis_connection_string[0]
  to   = azurerm_key_vault_secret.redis_connection_string
}
