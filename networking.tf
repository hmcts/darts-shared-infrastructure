resource "azurerm_virtual_network" "migration" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "migration-vnet"
  address_space       = concat(local.vnet_address_space, local.palo_address_space)
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name

  dns_servers = ["10.128.0.4", "10.128.0.5"]
  tags        = var.common_tags
}

moved {
  from = azurerm_virtual_network.migration
  to   = azurerm_virtual_network.migration[0]
}

resource "azurerm_subnet" "migration" {
  count                = local.is_migration_environment ? 1 : 0
  name                 = "migration-subnet"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  virtual_network_name = azurerm_virtual_network.migration[0].name
  address_prefixes     = [var.address_space]
}

moved {
  from = azurerm_subnet.migration
  to   = azurerm_subnet.migration[0]
}

resource "azurerm_network_security_group" "migration" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "darts-${var.env}-migration-nsg"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  tags                = var.common_tags
}

resource "azurerm_subnet_network_security_group_association" "migration" {
  count                     = local.is_migration_environment ? 1 : 0
  subnet_id                 = azurerm_subnet.migration[0].id
  network_security_group_id = azurerm_network_security_group.migration[0].id
}

resource "azurerm_network_security_rule" "allow_outbound_prddartsunstr" {
  count                       = local.is_migration_environment ? 1 : 0
  name                        = "allow-outbound-prddartsoracle"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.24.239.168"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.migration[0].name
  resource_group_name         = azurerm_resource_group.darts_migration_resource_group[0].name
}

resource "azurerm_network_security_rule" "dets-to-bias" {
  count                       = local.is_migration_environment ? 1 : 0
  name                        = "DetsToBIAS"
  priority                    = 130
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.224.251.4"
  network_security_group_name = azurerm_network_security_group.migration[0].name
  resource_group_name         = azurerm_resource_group.darts_migration_resource_group[0].name
}

resource "azurerm_network_security_rule" "block_internet" {
  count                       = local.is_migration_environment ? 1 : 0
  name                        = "BlockInternet"
  priority                    = 140
  direction                   = "Outbound"
  access                      = var.env == "prod" ? "Deny" : "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  network_security_group_name = azurerm_network_security_group.migration[0].name
  resource_group_name         = azurerm_resource_group.darts_migration_resource_group[0].name
}

resource "azurerm_network_security_rule" "deny_outbound_prddartsunstr" {
  count                       = local.is_migration_environment ? 1 : 0
  name                        = "deny-outbound-prddartsunstr"
  priority                    = 150
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.24.239.168"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.migration[0].name
  resource_group_name         = azurerm_resource_group.darts_migration_resource_group[0].name
}

resource "azurerm_subnet" "migration-extended" {
  count                = local.is_migration_environment && var.extended_address_space != null ? 1 : 0
  name                 = "migration-subnet-extended"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  virtual_network_name = azurerm_virtual_network.migration[0].name
  address_prefixes     = [var.extended_address_space]
}

resource "azurerm_subnet_network_security_group_association" "migration-extended" {
  count                     = local.is_migration_environment && var.extended_address_space != null ? 1 : 0
  subnet_id                 = azurerm_subnet.migration-extended[0].id
  network_security_group_id = azurerm_network_security_group.migration[0].id
}

data "azurerm_virtual_network" "hub-south-vnet" {
  count               = local.is_migration_environment ? 1 : 0
  provider            = azurerm.hub
  name                = local.hub[var.hub].ukSouth.name
  resource_group_name = local.hub[var.hub].ukSouth.name
}

resource "azurerm_virtual_network_peering" "darts_migration_to_hub" {
  count                        = local.is_migration_environment ? 1 : 0
  name                         = "darts-migration-to-hub-${var.env}"
  resource_group_name          = azurerm_resource_group.darts_migration_resource_group[0].name
  virtual_network_name         = azurerm_virtual_network.migration[0].name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub-south-vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

moved {
  from = azurerm_virtual_network_peering.darts_migration_to_hub
  to   = azurerm_virtual_network_peering.darts_migration_to_hub[0]
}

resource "azurerm_virtual_network_peering" "hub_to_darts_migration" {
  count                        = local.is_migration_environment ? 1 : 0
  provider                     = azurerm.hub
  name                         = "hub-to-darts-migration-${var.env}"
  resource_group_name          = local.hub[var.hub].ukSouth.name
  virtual_network_name         = local.hub[var.hub].ukSouth.name
  remote_virtual_network_id    = azurerm_virtual_network.migration[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

moved {
  from = azurerm_virtual_network_peering.hub_to_darts_migration
  to   = azurerm_virtual_network_peering.hub_to_darts_migration[0]
}

resource "azurerm_route_table" "route_table" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "darts-migration-rt-${var.env}"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  tags                = var.common_tags
}

moved {
  from = azurerm_route_table.route_table
  to   = azurerm_route_table.route_table[0]
}

resource "azurerm_route" "route" {
  count                  = local.is_migration_environment ? 1 : 0
  name                   = "DefaultRoute"
  resource_group_name    = azurerm_resource_group.darts_migration_resource_group[0].name
  route_table_name       = azurerm_route_table.route_table[0].name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub[var.hub].ukSouth.next_hop_ip
}

moved {
  from = azurerm_route.route
  to   = azurerm_route.route[0]
}

resource "azurerm_route" "firewall_routes" {
  for_each               = toset(var.firewall_route_ranges)
  name                   = "firewall_routes_${replace(split("/", each.value)[0], ".", "_")}"
  resource_group_name    = azurerm_resource_group.darts_migration_resource_group[0].name
  route_table_name       = azurerm_route_table.route_table[0].name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.palo["trust"].private_ip_address
}

resource "azurerm_subnet_route_table_association" "migrationRouteTable" {
  count          = local.is_migration_environment ? 1 : 0
  subnet_id      = azurerm_subnet.migration[0].id
  route_table_id = azurerm_route_table.route_table[0].id
}

resource "azurerm_subnet_route_table_association" "migration-extended" {
  count          = local.is_migration_environment && var.extended_address_space != null ? 1 : 0
  subnet_id      = azurerm_subnet.migration-extended[0].id
  route_table_id = azurerm_route_table.route_table[0].id
}

moved {
  from = azurerm_subnet_route_table_association.migrationRouteTable
  to   = azurerm_subnet_route_table_association.migrationRouteTable[0]
}
