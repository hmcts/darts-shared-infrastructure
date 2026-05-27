# Keyword YOUR has been used below for illustrative purposes only, please replace with your desired name in lowercase as appropriate

# terraform resource block utilising the new managed redis module 
# @ hmcts/terraform-module-azure-managed-redis
module "YOUR_managed_redis" {
  # foreach conditional allows selective deployment to desired environments
  for_each = toset(contains(["sandbox", "aat", "ithc", "perftest"], var.env) ? [var.env] : [])
  source   = "git@github.com:hmcts/terraform-module-azure-managed-redis?ref=main"
  
  product     = var.product
  component   = var.component       # NEW:        HMCTS component name — used to form the resource name |
  env         = var.env             
  location    = var.location
  common_tags = var.common_tags

  # Performance:
  sku_name = "Balanced_B0"          # NEW:        Be cautious, it's very expensive as usual

  # Networking:
  public_network_access   = "Disabled"
  create_private_endpoint = true
  subnet_id               = data.azurerm_subnet.redis_private_endpoint.id
  private_dns_zone_ids    = ["/subscriptions/${var.private_dns_subscription_id}/resourceGroups/core-infra-intsvc-rg/providers/Microsoft.Network/privateDnsZones/privatelink.redis.azure.net"]

  access_keys_authentication_enabled = true

  # Backup (persistence) options:
  persistence_rdb_backup_frequency   = "6h"
  # other available options (https://learn.microsoft.com/en-gb/azure/redis/how-to-persistence`):
  ## persistence_aof_backup_frequency
  ## geo_replication_group_name
}



# the name of the terraform resource secret has been kept the same to ease adoption
# the new instance's secret will be saved to your keyvault secret. The older infra's
# secrets will be visible as an 'older version' on the key vault
resource "azurerm_key_vault_secret" "redis_connection_string" {
  name         = "redis-connection-string"              
  value        = "rediss://:${urlencode(module.YOUR_managed_redis.access_key)}@${module.YOUR_redis.host_name}:${module.YOUR_redis.redis_port}?tls=true"
  key_vault_id = module.YOUR_key_vault.key_vault_id
}

# If you'd like to create a new secret rather than overwriting the existing secret use this block instead:
resource "azurerm_key_vault_secret" "managed_redis_connection_string" {
  name         = "managed-redis-connection-string"              
  value        = "rediss://:${urlencode(module.YOUR_managed_redis.access_key)}@${module.YOUR_redis.host_name}:${module.YOUR_redis.redis_port}?tls=true"
  key_vault_id = module.YOUR_key_vault.key_vault_id
}



## N.B.
# when you have deployed to all of your environments, you may replace the foreach conditional with
#     for_each = toset([var.env])
# this will keep the terraform resource as is

# alternatively if you would like to remove the redundant foreach, you will have to utilise a terraform 'moved' 
# block to tell terraform the resource still exists, it has simply been moved to a new references
# e.g.
moved {
  from = module.darts_redis[0]
  to   = module.darts_redis
}

moved {
  from = azurerm_key_vault_secret.redis_connection_string[0]
  to   = azurerm_key_vault_secret.redis_connection_string
}