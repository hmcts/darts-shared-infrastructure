resource "azurerm_virtual_network" "migration" {
  for_each = var.env == "prod" || "stg" ? 1 : {}
  name                = "migration-vnet"
  address_space       = concat([var.address_space, var.postgres_subnet_address_space], local.palo_address_space)
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  tags                = var.common_tags
}

resource "azurerm_subnet" "migration" {
  for_each = var.env == "prod" || "stg" ? 1 : {}
  name                 = "migration-subnet"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name = azurerm_virtual_network.migration.name
  address_prefixes     = [var.address_space]
}

data "azurerm_virtual_network" "hub-south-vnet" {
  provider            = azurerm.hub
  name                = local.hub[var.hub].ukSouth.name
  resource_group_name = local.hub[var.hub].ukSouth.name
}

resource "azurerm_virtual_network_peering" "darts_migration_to_hub" {
  for_each = var.env == "prod" || "stg" ? 1 : {}
  name                         = "darts-migration-to-hub-${var.env}"
  resource_group_name          = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name         = azurerm_virtual_network.migration.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub-south-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "hub_to_darts_migration" {
  for_each = var.env == "prod" || "stg" ? 1 : {}
  provider                     = azurerm.hub
  name                         = "hub-to-darts-migration-${var.env}"
  resource_group_name          = local.hub[var.hub].ukSouth.name
  virtual_network_name         = local.hub[var.hub].ukSouth.name
  remote_virtual_network_id    = azurerm_virtual_network.migration.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_route_table" "route_table" {
  for_each = var.env == "prod" || "stg" ? 1 : {}
  name                = "darts-migration-rt-${var.env}"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  location            = azurerm_resource_group.darts_migration_resource_group.location
  tags                = var.common_tags
}

resource "azurerm_route" "route" {
  for_each = var.env == "prod" || "stg" ? 1 : {}
  name                   = "DefaultRoute"
  resource_group_name    = azurerm_resource_group.darts_migration_resource_group.name
  route_table_name       = azurerm_route_table.route_table.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub[var.hub].ukSouth.next_hop_ip
}

resource "azurerm_route" "firewall_routes" {
  for_each = var.env == "prod" || "stg" ? toset(var.firewall_route_ranges) : {}

  name                   = "firewall_routes_${replace(split("/", each.value)[0], ".", "_")}"
  resource_group_name    = azurerm_resource_group.darts_migration_resource_group.name
  route_table_name       = azurerm_route_table.route_table.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.palo["trust"].private_ip_address
}

resource "azurerm_subnet_route_table_association" "migrationRouteTable" {
  for_each = var.env == "prod" || "stg" ? 1 : {}
  subnet_id      = azurerm_subnet.migration.id
  route_table_id = azurerm_route_table.route_table.id
}
