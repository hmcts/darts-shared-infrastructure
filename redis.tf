module "darts_redis" {
  count         = contains(["stg", "prod","demo"], var.env) ? 1 : 0
  source        = "git@github.com:hmcts/cnp-module-redis?ref=master"
  product       = var.product
  location      = var.location
  env           = var.env
  common_tags   = var.common_tags
  redis_version = "6"
  business_area = "sds"

  private_endpoint_enabled      = true
  public_network_access_enabled = false
  sku_name                      = var.sku_name
  family                        = var.family
  capacity                      = var.capacity

}

resource "azurerm_key_vault_secret" "redis_connection_string" {
  count = contains(["stg", "prod","demo"], var.env) ? 1 : 0
  name  = "redis-connection-string"
  value = "rediss://:${urlencode(module.darts_redis[0].access_key)}@${module.darts_redis[0].host_name}:${module.darts_redis[0].redis_port}?tls=true"

  key_vault_id = module.darts_key_vault.key_vault_id
}
