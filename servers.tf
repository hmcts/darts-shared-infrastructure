locals {
  vault_name = "${var.product}-migration-${var.env}"
  rg_name    = "${var.product}-migration-${var.env}-rg"
}

data "azurerm_resource_group" "darts_resource_migration_group" {
    name     = format("%s-migration-%s-rg", var.product, var.env)
}

data "azurerm_key_vault" "key_vault" {
  name                = local.vault_name
  resource_group_name = local.rg_name
}

resource "azurerm_virtual_network" "migration" {
  name                = "migration-vnet"
  address_space       = var.ip_range
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
}

resource "azurerm_subnet" "migration" {
  name                 = "migration-subnet"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name = azurerm_virtual_network.migration.name
  address_prefixes     = var.ip_range
}

resource "azurerm_network_interface" "migration" {
  name                = "migration-nic"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name

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
  create_option        = "FromImage"
  disk_size_gb         = 20
}

resource "azurerm_managed_disk" "migration_data" {
  name                 = "migration-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 200
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_virtual_machine" "migration" {
  name                  = "migration-vm"
  location              = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name   = azurerm_resource_group.darts_migration_resource_group.name
  network_interface_ids = [azurerm_network_interface.migration.id]
  vm_size               = "Standard_D8_v3"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = azurerm_managed_disk.migration_os.name
    managed_disk_id   = azurerm_managed_disk.migration_os.id
    create_option     = "Attach"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = azurerm_managed_disk.migration_data.name
    managed_disk_id   = azurerm_managed_disk.migration_data.id
    create_option     = "Attach"
    caching           = "None"
    managed_disk_type = "Standard_LRS"
    lun               = 0
  }

  os_profile {
    computer_name  = "migration-vm"
    admin_username = "adminuser"
    admin_password = random_password.password.result
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
resource "azurerm_key_vault_secret" "os_profile_password" {
  name         = "os_profile_password"
  value        = random_password.password.result
  key_vault_id = data.azurerm_key_vault.key_vault.id
}

