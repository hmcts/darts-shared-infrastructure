locals {
  vault_name = "${var.product}-${var.env}"
  migration_vault_name = "${var.product}-migration-${var.env}"
  rg_name    = azurerm_resource_group.darts_migration_resource_group.name
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
  storage_account_name = "${var.product}sa${var.env}"
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
  darts_container_name    = "darts-st-container"
  darts_inbound_container = "darts-inbound-container"  
  db_name    = "darts-migration"
  db_port    = 5432
}
