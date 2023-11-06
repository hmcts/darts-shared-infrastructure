resource "azurerm_public_ip" "firewall_public_ip" {
  name                = "firewall-pip-${var.env}"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

resource "azurerm_log_analytics_workspace" "firewall_log_analytics" {
  count               = var.firewall_log_analytics_enabled ? 1 : 0
  name                = "darts-migration-log-analytics-${var.env}"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 5
  tags                = var.common_tags
}

resource "azurerm_firewall" "migration_firewall" {
  name                = "darts-migration-firewall-${var.env}"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  tags                = var.common_tags
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.migration_policy.id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_public_ip.id
  }
}

resource "azurerm_firewall_policy" "migration_policy" {
  name                = "darts-migration-policy-${var.env}"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  location            = azurerm_resource_group.darts_migration_resource_group.location
  tags                = var.common_tags

  dynamic "insights" {
    for_each = var.firewall_log_analytics_enabled ? [0] : []
    content {
      retention_in_days                  = 30
      enabled                            = true
      default_log_analytics_workspace_id = azurerm_log_analytics_workspace.firewall_log_analytics[0].id
      log_analytics_workspace {
        id                = azurerm_log_analytics_workspace.firewall_log_analytics[0].id
        firewall_location = azurerm_resource_group.darts_migration_resource_group.location
      }
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "migration_policy_rules" {
  name               = "darts-migration-fwpolicyrules-${var.env}"
  firewall_policy_id = azurerm_firewall_policy.migration_policy.id
  priority           = var.firewall_policy_priority

  dynamic "application_rule_collection" {
    for_each = var.firewall_application_rules
    content {
      name     = application_rule_collection.key
      action   = application_rule_collection.value.action
      priority = application_rule_collection.value.priority
      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name        = rule.key
          description = rule.value.description
          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              port = protocols.value.port
              type = protocols.value.type
            }
          }
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          source_ip_groups      = rule.value.source_ip_groups
          destination_fqdns     = rule.value.destination_fqdns
        }
      }
    }
  }

  dynamic "network_rule_collection" {
    for_each = var.firewall_network_rules
    content {
      name     = network_rule_collection.key
      action   = network_rule_collection.value.action
      priority = network_rule_collection.value.priority
      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.key
          protocols             = rule.value.protocols
          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
          destination_addresses = rule.value.destination_addresses
          destination_ip_groups = rule.value.destination_ip_groups
          destination_fqdns     = rule.value.destination_fqdns
          destination_ports     = rule.value.destination_ports
        }
      }
    }
  }

  dynamic "nat_rule_collection" {
    for_each = var.firewall_nat_rules
    content {
      name     = nat_rule_collection.key
      action   = nat_rule_collection.value.action
      priority = nat_rule_collection.value.priority
      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.key
          protocols           = rule.value.protocols
          source_addresses    = rule.value.source_addresses
          source_ip_groups    = rule.value.source_ip_groups
          destination_address = azurerm_firewall.migration_firewall.ip_configuration[0].private_ip_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_fqdn     = rule.value.translated_fqdn
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}

resource "azurerm_public_ip" "palo" {
  for_each            = { for key, value in var.palo_networks : key => value if value.public_ip_required }
  name                = "darts-palo-pip-${each.key}-${var.env}"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

resource "azurerm_subnet" "palo" {
  for_each             = var.palo_networks
  name                 = "darts-migration-palo-${each.key}-${var.env}"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name = azurerm_virtual_network.migration.name
  address_prefixes     = [each.value.address_space]
}

resource "azurerm_network_security_group" "palo" {
  for_each            = var.palo_networks
  name                = "darts-migration-palo-${each.key}-nsg-${var.env}"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  tags                = var.common_tags
}

resource "azurerm_network_security_rule" "deny_inbound" {
  for_each                    = { for key, value in var.palo_networks : key => value if value.nsg_deny_inbound }
  network_security_group_name = azurerm_network_security_group.palo[each.key].name
  resource_group_name         = azurerm_resource_group.darts_migration_resource_group.name
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

resource "azurerm_network_security_rule" "this" {
  for_each                                   = { for rule in local.flattened_nsg_rules : "${rule.network_key}-${rule.rule_key}" => rule }
  network_security_group_name                = azurerm_network_security_group.palo[each.value.network_key].name
  resource_group_name                        = azurerm_resource_group.darts_migration_resource_group.name
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

resource "azurerm_subnet_network_security_group_association" "palo" {
  for_each                  = var.palo_networks
  subnet_id                 = azurerm_subnet.palo[each.key].id
  network_security_group_id = azurerm_network_security_group.palo[each.key].id
}

resource "azurerm_network_interface" "palo" {
  for_each            = var.palo_networks
  name                = "darts-migration-palo-vm01-${each.key}-nic-${var.env}"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name

  ip_configuration {
    name                          = "darts-migration-palo-vm01-${each.key}-nic-${var.env}"
    subnet_id                     = azurerm_subnet.palo[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.public_ip_required ? azurerm_public_ip.palo[each.key].id : null
  }

  tags = var.common_tags
}

resource "random_password" "palo_password" {
  length           = 16
  special          = true
  min_special      = 1
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "palo_password" {
  name         = "darts-migration-palo-vm01-${var.env}"
  value        = random_password.palo_password.result
  key_vault_id = module.darts_migration_key_vault.key_vault_id

  depends_on = [module.darts_migration_key_vault]
}

resource "azurerm_linux_virtual_machine" "palo" {
  name                = "darts-migration-palo-vm01-${var.env}"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  location            = azurerm_resource_group.darts_migration_resource_group.location
  size                = "Standard_D8ds_v5"

  network_interface_ids = [for key, network in var.palo_networks : azurerm_network_interface.palo[key].id]

  admin_username                  = "dartsadmin"
  admin_password                  = random_password.palo_password.result
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = "bundle2"
    version   = "latest"
  }

  plan {
    name      = "bundle2"
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  tags = var.common_tags
}
