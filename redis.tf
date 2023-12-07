module "darts_redis" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
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
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name  = "redis-connection-string"
  value = "rediss://:${urlencode(module.darts_redis[each.key].access_key)}@${module.darts_redis[each.key].host_name}:${module.darts_redis[each.key].redis_port}?tls=true"

  key_vault_id = module.darts_key_vault.key_vault_id
}
