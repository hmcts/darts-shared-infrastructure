resource "azurerm_virtual_network" "migration" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                = "migration-vnet"
  address_space       = concat([var.address_space, var.postgres_subnet_address_space], local.palo_address_space)
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  tags                = var.common_tags
}

resource "azurerm_subnet" "migration" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                 = "migration-subnet"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  virtual_network_name = azurerm_virtual_network.migration[0].name
  address_prefixes     = [var.address_space]
}

data "azurerm_virtual_network" "hub-south-vnet" {
  provider            = azurerm.hub
  name                = local.hub[var.hub].ukSouth.name
  resource_group_name = local.hub[var.hub].ukSouth.name
}

resource "azurerm_virtual_network_peering" "darts_migration_to_hub" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                         = "darts-migration-to-hub-${var.env}"
  resource_group_name          = azurerm_resource_group.darts_migration_resource_group[0].name
  virtual_network_name         = azurerm_virtual_network.migration[0].name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub-south-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "hub_to_darts_migration" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  provider                     = azurerm.hub
  name                         = "hub-to-darts-migration-${var.env}"
  resource_group_name          = local.hub[var.hub].ukSouth.name
  virtual_network_name         = local.hub[var.hub].ukSouth.name
  remote_virtual_network_id    = azurerm_virtual_network.migration[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_route_table" "route_table" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                = "darts-migration-rt-${var.env}"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  tags                = var.common_tags
}

resource "azurerm_route" "route" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                   = "DefaultRoute"
  resource_group_name    = azurerm_resource_group.darts_migration_resource_group[0].name
  route_table_name       = azurerm_route_table.route_table[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub[var.hub].ukSouth.next_hop_ip
}

resource "azurerm_route" "firewall_routes" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                   = "firewall_routes_${replace(split("/", each.value)[0], ".", "_")}"
  resource_group_name    = azurerm_resource_group.darts_migration_resource_group[0].name
  route_table_name       = azurerm_route_table.route_table[0].name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.palo["trust"].private_ip_address
}

resource "azurerm_subnet_route_table_association" "migrationRouteTable" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  subnet_id      = azurerm_subnet.migration[0].id
  route_table_id = azurerm_route_table.route_table[0].id
}
