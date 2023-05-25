provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "darts_resource_migration_group" {
    name     = format("%s-migration-%s-rg", var.product, var.env)
}
data "azurerm_key_vault_secret" "ipAddress" {
  name = "ipAddress"
}
resource "azurerm_virtual_network" "migration" {
  name                = "migration-vnet"
  address_space       = azurerm_key_vault_secret.ipAddress.value
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
}

resource "azurerm_subnet" "migration" {
  name                 = "migration-subnet"
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  virtual_network_name = azurerm_virtual_network.migration.name
  address_prefixes     = azurerm_key_vault_secret.ipAddress.value
}



resource "azurerm_network_interface" "migration" {
  name                = "migration-nic"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name

  ip_configuration {
    name                          = "migration-ipconfig"
    subnet_id                     = azurerm_subnet.migration.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_id          = azurerm_public_ip.migration.id
  }
}

resource "azurerm_managed_disk" "migration_os" {
  name                 = "migration-osdisk"
  location             = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "FromImage"
  disk_size_gb         = 200
}

resource "azurerm_managed_disk" "migration_data" {
  name                 = "migration-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 200
}

resource "azurerm_virtual_machine" "migration" {
  name                  = "migration-vm"
  location              = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name   = azurerm_resource_group.darts_migration_resource_group.name
  network_interface_ids = [azurerm_network_interface.migration.id]
  vm_size               = "Standard_DS3_v2"

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
  }

  os_profile {
    computer_name  = "migration-vm"
    admin_username = "adminuser"
    admin_password = "Password123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
