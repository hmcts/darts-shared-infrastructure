resource "azurerm_public_ip" "palo" {
  for_each = contains(["stg", "prod"], var.env) ? { for key, value in var.palo_networks : key => value if value.public_ip_required } : {}
  name                = "darts-palo-pip-${each.key}-${var.env}"
  domain_name_label   = "darts-migration-palo-${var.env}"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

resource "azurerm_subnet" "palo" {
  for_each = contains(["stg", "prod"], var.env) ? var.palo_networks : {}
  name                 = "darts-migration-palo-${each.key}-${var.env}"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name = azurerm_virtual_network.migration.name
  address_prefixes     = [each.value.address_space]
}

resource "azurerm_network_security_group" "palo" {
  for_each = contains(["stg", "prod"], var.env) ? var.palo_networks : {}
  name                = "darts-migration-palo-${each.key}-nsg-${var.env}"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  tags                = var.common_tags
}

resource "azurerm_network_security_rule" "deny_inbound" {
  for_each = contains(["stg", "prod"], var.env) ? { for key, value in var.palo_networks : key => value if value.nsg_deny_inbound } : {}
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
  for_each = contains(["stg", "prod"], var.env) ? { for rule in local.flattened_nsg_rules : "${rule.network_key}-${rule.rule_key}" => rule } : {}
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
  for_each = contains(["stg", "prod"], var.env) ? var.palo_networks : {}
  subnet_id                 = azurerm_subnet.palo[each.key].id
  network_security_group_id = azurerm_network_security_group.palo[each.key].id
}

resource "azurerm_network_interface" "palo" {
  for_each = contains(["stg", "prod"], var.env) ? var.palo_networks : {}
  name                 = "darts-migration-palo-vm01-${each.key}-nic-${var.env}"
  location             = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  enable_ip_forwarding = each.value.enable_ip_forwarding

  ip_configuration {
    name                          = "darts-migration-palo-vm01-${each.key}-nic-${var.env}"
    subnet_id                     = azurerm_subnet.palo[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.value.public_ip_required ? azurerm_public_ip.palo[each.key].id : null
  }

  tags = var.common_tags
}

resource "random_password" "palo_password" {
  count            = length(var.palo_networks) > 0 ? 1 : 0
  length           = 16
  special          = true
  min_special      = 1
  min_numeric      = 1
  min_lower        = 1
  min_upper        = 1
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "palo_password" {
  for_each = contains(["stg", "prod"], var.env) ? var.palo_networks : {}
  count        = length(var.palo_networks) > 0 ? 1 : 0
  name         = "darts-migration-palo-vm01-${var.env}"
  value        = random_password.palo_password[0].result
  key_vault_id = module.darts_migration_key_vault.key_vault_id

  depends_on = [module.darts_migration_key_vault]
}

resource "azurerm_linux_virtual_machine" "palo" {
  for_each = contains(["stg", "prod"], var.env) ? var.palo_networks : {}
  count               = length(var.palo_networks) > 0 ? 1 : 0
  name                = "darts-migration-palo-vm01-${var.env}"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  location            = azurerm_resource_group.darts_migration_resource_group.location
  size                = "Standard_D8ds_v5"

  network_interface_ids = [for key, network in var.palo_networks : azurerm_network_interface.palo[key].id]

  admin_username                  = "dartsadmin"
  admin_password                  = random_password.palo_password[0].result
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries-flex"
    sku       = "byol"
    version   = "latest"
  }

  plan {
    name      = "byol"
    publisher = "paloaltonetworks"
    product   = "vmseries-flex"
  }

  tags = var.common_tags
}
