locals {
  vault_name = "${var.product}-migration-${var.env}"
  rg_name    = "${var.product}-migration-${var.env}-rg"
  hub = {
    nonprod = {
      subscription = "fb084706-583f-4c9a-bdab-949aac66ba5c"
      ukSouth = {
        name = "hmcts-hub-nonprodi"
        next_hop_ip = "10.11.72.36"
      }
    }
    sbox = {
      subscription = "ea3a8c1e-af9d-4108-bc86-a7e2d267f49c"
      ukSouth = {
        name = "hmcts-hub-sbox-int"
        next_hop_ip = "10.10.200.36"
      }
    }
    prod = {
      subscription = "0978315c-75fe-4ada-9d11-1eb5e0e0b214"
      ukSouth = {
        name = "hmcts-hub-prod-int"
        next_hop_ip = "10.11.8.36"
      }
    }
  }
}

provider "azurerm" {
  alias                      = "hub"
  skip_provider_registration = "true"
  version                    = "3.54"
  features {}
  subscription_id            = local.hub[var.hub].subscription
}

data "azurerm_resource_group" "darts_resource_migration_group" {
    name     = format("%s-migration-%s-rg", var.product, var.env)
}

resource "azurerm_virtual_network" "migration" {
  name                = "migration-vnet"
  address_space       =  [var.address_space]
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
  address_prefixes     = [var.address_space]

   lifecycle {
    ignore_changes = [
      address_prefixes,
      service_endpoints,
    ]
  }
}

data "azurerm_virtual_network" "hub-south-vnet" {
  provider            = azurerm.hub
  name                = local.hub[var.hub].ukSouth.name
  resource_group_name = local.hub[var.hub].ukSouth.name
}


resource "azurerm_virtual_network_peering" "darts_migration_to_hub" {
  name                 = "darts-migration-to-hub-${var.env}"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name = azurerm_virtual_network.migration.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub-south-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit = false
}

resource "azurerm_virtual_network_peering" "hub_to_darts_migration" {
  provider             = azurerm.hub
  name                 = "hub-to-darts-migration-${var.env}"
  resource_group_name  = local.hub[var.hub].ukSouth.name
  virtual_network_name = local.hub[var.hub].ukSouth.name
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
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address =  local.hub[var.hub].ukSouth.next_hop_ip
}

resource "azurerm_subnet_route_table_association" "migrationRouteTable" {
  subnet_id      = azurerm_subnet.migration.id
  route_table_id = azurerm_route_table.peering.id
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
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "88-gen2"
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

resource "azurerm_virtual_machine_extension" "migration_aad" {
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

resource "azurerm_key_vault_secret" "os_profile_password" {
  name         = "os-profile-password"
  value        = random_password.password.result
  key_vault_id = module.darts_key_vault.key_vault_id
}
