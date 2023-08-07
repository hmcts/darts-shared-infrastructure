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
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = rule.value.translated_address
          translated_fqdn     = rule.value.translated_fqdn
          translated_port     = rule.value.translated_port
        }
      }
    }
  }
}
