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

  admin_ssh_key {
    username   = var.admin_user
    public_key = random_password.password.result
  }

  os_disk {
    name              = azurerm_managed_disk.migration_os.name
    managed_disk_id   = azurerm_managed_disk.migration_os.id
    create_option     = "Attach"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  os_disk {
    name              = azurerm_managed_disk.migration_data.name
    managed_disk_id   = azurerm_managed_disk.migration_data.id
    create_option     = "Attach"
    caching           = "None"
    managed_disk_type = "Standard_LRS"

  }

  # os_profile {
  #   computer_name  = "migration-vm"
  #   admin_username = "adminuser"
  #   admin_password = random_password.password.result
  # }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }

}
  



resource "azurerm_key_vault_secret" "os_profile_password" {
  name         = "os-profile-password"
  value        = random_password.password.result
  key_vault_id = module.darts_key_vault.key_vault_id
}

