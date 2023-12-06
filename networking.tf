resource "azurerm_virtual_network" "migration" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                = "migration-vnet"
  address_space       = concat([var.address_space, var.postgres_subnet_address_space], local.palo_address_space)
  location            = azurerm_resource_group.darts_migration_resource_group[each.key].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[each.key].name
  tags                = var.common_tags
}

resource "azurerm_subnet" "migration" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                 = "migration-subnet"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[each.key].name
  virtual_network_name = azurerm_virtual_network.migration[each.key].name
  address_prefixes     = [var.address_space]
}

data "azurerm_virtual_network" "hub-south-vnet" {
  provider            = azurerm.hub
  name                = local.hub[var.hub].ukSouth.name
  resource_group_name = local.hub[var.hub].ukSouth.name
}

resource "azurerm_virtual_network_peering" "darts_migration_to_hub" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                         = "darts-migration-to-hub-${var.env}"
  resource_group_name          = azurerm_resource_group.darts_migration_resource_group[each.key].name
  virtual_network_name         = azurerm_virtual_network.migration[each.key].name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub-south-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "hub_to_darts_migration" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  provider                     = azurerm.hub
  name                         = "hub-to-darts-migration-${var.env}"
  resource_group_name          = local.hub[var.hub].ukSouth.name
  virtual_network_name         = local.hub[var.hub].ukSouth.name
  remote_virtual_network_id    = azurerm_virtual_network.migration[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_route_table" "route_table" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                = "darts-migration-rt-${var.env}"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[each.key].name
  location            = azurerm_resource_group.darts_migration_resource_group[each.key].location
  tags                = var.common_tags
}

resource "azurerm_route" "route" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                   = "DefaultRoute"
  resource_group_name    = azurerm_resource_group.darts_migration_resource_group[each.key].name
  route_table_name       = azurerm_route_table.route_table[each.key].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub[var.hub].ukSouth.next_hop_ip
}

resource "azurerm_route" "firewall_routes" {
  for_each = contains(["stg", "prod"], var.env) ? toset(var.firewall_route_ranges) : {}
  name                   = "firewall_routes_${replace(split("/", each.value)[0], ".", "_")}"
  resource_group_name    = azurerm_resource_group.darts_migration_resource_group[each.key].name
  route_table_name       = azurerm_route_table.route_table.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.palo["trust"].private_ip_address
}

resource "azurerm_subnet_route_table_association" "migrationRouteTable" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  subnet_id      = azurerm_subnet.migration.id
  route_table_id = azurerm_route_table.route_table.id
}
