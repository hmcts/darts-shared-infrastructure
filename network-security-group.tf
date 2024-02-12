resource "azurerm_network_security_group" "this" {
  for_each            = var.network_security_groups
  name                = each.value.name_override == null ? "${var.product}-${each.key}-${var.env}" : each.value.name_override
  resource_group_name = each.value.resource_group_override == null ? azurerm_resource_group.darts_migration_resource_group[0] : each.value.resource_group_override
  location            = var.location
  tags                = var.common_tags
}

resource "azurerm_network_security_rule" "rules" {
  for_each                                   = { for rule in local.flattened_nsg_rules : "${rule.nsg_key}-${rule.rule_key}" => rule }
  network_security_group_name                = azurerm_network_security_group.this[each.value.nsg_key].name
  resource_group_name                        = azurerm_network_security_group.this[each.value.nsg_key].resource_group_name
  name                                       = each.value.rule.name_override == null ? each.key : each.value.rule.name_override
  priority                                   = each.value.rule.priority
  direction                                  = each.value.rule.direction
  access                                     = each.value.rule.access
  protocol                                   = each.value.rule.protocol
  source_port_range                          = each.value.rule.source_port_range
  source_port_ranges                         = each.value.rule.source_port_ranges
  destination_port_range                     = each.value.rule.destination_port_range
  destination_port_ranges                    = each.value.rule.destination_port_ranges
  source_address_prefix                      = each.value.rule.source_address_prefix
  source_address_prefixes                    = each.value.rule.source_address_prefixes
  source_application_security_group_ids      = each.value.rule.source_application_security_group_ids
  destination_address_prefix                 = each.value.rule.destination_address_prefix
  destination_address_prefixes               = each.value.rule.destination_address_prefixes
  destination_application_security_group_ids = each.value.rule.destination_application_security_group_ids
  description                                = each.value.rule.description
}

resource "azurerm_network_security_rule" "deny_inbound" {
  for_each                    = { for key, value in var.network_security_groups : key => value if value.deny_inbound == true }
  network_security_group_name = azurerm_network_security_group.this[each.key].name
  resource_group_name         = azurerm_network_security_group.this[each.key].resource_group_name
  name                        = "DenyAllInbound"
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  priority                    = 4096 # The lowest priority possible via Terraform
  description                 = "Default DenyInbound rule"
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = { for nsg in local.flattened_subnet_nsg_associations : "${nsg.nsg_key}-${nsg.subnet}" => nsg }
  subnet_id                 = azurerm_subnet.this[each.value.subnet].id
  network_security_group_id = azurerm_network_security_group.this[each.value.nsg_key].id
}