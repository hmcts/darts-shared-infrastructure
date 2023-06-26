locals {
  vault_name = "${var.product}-migration-${var.env}"
  rg_name    = "${var.product}-migration-${var.env}-rg"
}

data "azurerm_resource_group" "darts_resource_migration_group" {
    name     = format("%s-migration-%s-rg", var.product, var.env)
}


resource "azurerm_virtual_network" "migration" {
  name                = "migration-vnet"
  address_space       = var.ip_range
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      address_space,
    ]
  }
}

resource "azurerm_subnet" "migration" {
  name                 = "migration-subnet"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name = azurerm_virtual_network.migration.name
  address_prefixes     = var.ip_range

   lifecycle {
    ignore_changes = [
      address_prefixes,
      service_endpoints,
    ]
  }
}

data "azurerm_resource_group" "darts_peer_resource_group" {
    name     = format("%s-peer-%s-rg", var.product, var.env)
}


resource "azurerm_virtual_network" "peerVN" {
  name                = "peer-vnet"
  address_space       = var.ip_range_2
  location            = data.azurerm_resource_group.darts_peer_resource_group.location
  resource_group_name = data.azurerm_resource_group.darts_peer_resource_group.name
  tags = var.common_tags
  lifecycle {
    ignore_changes = [
      address_space,
    ]
  }
}

resource "azurerm_subnet" "peerSubnet" {
  name                 = "peer-subnet"
  resource_group_name  = data.azurerm_resource_group.darts_peer_resource_group.name
  virtual_network_name = azurerm_virtual_network.peerVN.name
  address_prefixes     = var.ip_range_2

   lifecycle {
    ignore_changes = [
      address_prefixes,
      service_endpoints,
    ]
  }
}

resource "azurerm_virtual_network_peering" "migration_to_peering" {
  name                 = "VNet1-to-VNet2"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name = azurerm_virtual_network.migration.name
  remote_virtual_network_id = azurerm_virtual_network.peerVN.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit = false
}

resource "azurerm_virtual_network_peering" "peering_to_migration" {
  name                 = "VNet2-to-VNet2"
  resource_group_name  = data.azurerm_resource_group.darts_peer_resource_group.name
  virtual_network_name = azurerm_virtual_network.peerVN.name
  remote_virtual_network_id = azurerm_virtual_network.migration.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit = false
}

resource "azurerm_route_table" "peering" {
  name                = "vnetToPauloAlto"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  location            = azurerm_resource_group.darts_migration_resource_group.location
  tags                = var.common_tags
}

resource "azurerm_route" "route" {
  name                = "DefaultRoute"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  route_table_name    = azurerm_route_table.peering.name
  address_prefix      = var.env == "prod" ? var.paloaltoProd : var.paloaltoNonProd 
  next_hop_type       = "VirtualNetworkGateway"
}



resource "azurerm_network_interface" "migration" {
  name                = "migration-nic"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  tags = var.common_tags

  ip_configuration {
    name                          = "migration-ipconfig"
    subnet_id                     = azurerm_subnet.migration.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "migration_os" {
  name                 = "migration-osdisk"
  location             = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
  tags = var.common_tags
}

resource "azurerm_managed_disk" "migration_data" {
  name                 = "migration-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags = var.common_tags
}

resource "azurerm_linux_virtual_machine" "migration" {
  name                  = "migration-vm"
  location              = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name   = azurerm_resource_group.darts_migration_resource_group.name
  network_interface_ids = [azurerm_network_interface.migration.id]
  size                  = "Standard_D8ds_v5"
  tags                  = var.common_tags
  admin_username        = var.admin_user
  admin_password        = random_password.password.result
  disable_password_authentication = false

  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }

}
  
resource "azurerm_virtual_machine_data_disk_attachment" "datadisk" {
  managed_disk_id    = azurerm_managed_disk.migration_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.migration.id
  lun                = "10"
  caching            = "ReadWrite"
}


resource "azurerm_key_vault_secret" "os_profile_password" {
  name         = "os-profile-password"
  value        = random_password.password.result
  key_vault_id = module.darts_key_vault.key_vault_id
}