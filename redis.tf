module "darts_redis" {
  source                   = "git@github.com:hmcts/cnp-module-redis?ref=master"
  product                  = var.product
  location                 = var.location
  env                      = var.env
  common_tags              = var.common_tags
  redis_version            = "6"
  business_area            = "sds"

  private_endpoint_enabled      = true
  public_network_access_enabled = false
}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"
  value        = "rediss://:${urlencode(module.darts_redis.access_key)}@${module.darts_redis.host_name}:${module.darts_redis.redis_port}?tls=true"

  key_vault_id = module.darts_key_vault.key_vault_id
}
