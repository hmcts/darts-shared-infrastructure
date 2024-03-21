resource "azurerm_virtual_network" "modernisation" {
  count               = local.is_test_environment ? 1 : 0
  name                = "modernisation-vnet"
  address_space       = concat(local.vnet_address_space, local.palo_address_space)
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name

  dns_servers = ["10.128.0.4", "10.128.0.5"]
  tags        = var.common_tags
}

resource "azurerm_subnet" "modernisation" {
  count                = local.is_test_environment ? 1 : 0
  name                 = "modernisation-subnet"
  resource_group_name  = azurerm_resource_group.darts_resource_group.name
  virtual_network_name = azurerm_virtual_network.modernisation[0].name
  address_prefixes     = [var.address_space]
}

resource "azurerm_network_security_group" "modernisation" {
  count               = local.is_test_environment ? 1 : 0
  name                = "darts-${var.env}-modernisaton-nsg"
  resource_group_name = azurerm_resource_group.darts_resource_group.name
  location            = azurerm_resource_group.darts_resource_group.location
  tags                = var.common_tags
}

resource "azurerm_subnet_network_security_group_association" "modernisation" {
  count                     = local.is_test_environment ? 1 : 0
  subnet_id                 = azurerm_subnet.modernisation[0].id
  network_security_group_id = azurerm_network_security_group.modernisation[0].id
}

data "azurerm_virtual_network" "hub-south-vnet-modern" {
  count               = local.is_test_environment ? 1 : 0
  provider            = azurerm.hub
  name                = local.hub[var.hub].ukSouth.name
  resource_group_name = local.hub[var.hub].ukSouth.name
}

resource "azurerm_virtual_network_peering" "darts_modernisation_to_hub" {
  count                        = local.is_test_environment ? 1 : 0
  name                         = "darts-modernisation-to-hub-${var.env}"
  resource_group_name          = azurerm_resource_group.darts_resource_group.name
  virtual_network_name         = azurerm_virtual_network.modernisation[0].name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub-south-vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "hub_to_darts_modernisation" {
  count                        = local.is_test_environment ? 1 : 0
  provider                     = azurerm.hub
  name                         = "hub-to-darts-modernisation-${var.env}"
  resource_group_name          = local.hub[var.hub].ukSouth.name
  virtual_network_name         = local.hub[var.hub].ukSouth.name
  remote_virtual_network_id    = azurerm_virtual_network.modernisation[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_route_table" "route_table_modern" {
  count               = local.is_test_environment ? 1 : 0
  name                = "darts-migration-rt-${var.env}"
  resource_group_name = azurerm_resource_group.darts_resource_group.name
  location            = azurerm_resource_group.darts_resource_group.location
  tags                = var.common_tags
}

resource "azurerm_route" "route_modern" {
  count                  = local.is_test_environment ? 1 : 0
  name                   = "DefaultRoute"
  resource_group_name    = azurerm_resource_group.darts_resource_group.name
  route_table_name       = azurerm_route_table.route_table[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub[var.hub].ukSouth.next_hop_ip
}

resource "azurerm_route" "firewall_routes_modern" {
  for_each               = toset(var.firewall_route_ranges)
  name                   = "firewall_routes_${replace(split("/", each.value)[0], ".", "_")}"
  resource_group_name    = azurerm_resource_group.darts_resource_group.name
  route_table_name       = azurerm_route_table.route_table[0].name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.palo["trust"].private_ip_address
}

resource "azurerm_subnet_route_table_association" "modernisationRouteTable" {
  count          = local.is_test_environment ? 1 : 0
  subnet_id      = azurerm_subnet.modernisation[0].id
  route_table_id = azurerm_route_table.route_table_modern[0].id
}