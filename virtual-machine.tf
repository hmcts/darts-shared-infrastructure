resource "azurerm_network_interface" "migration" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                = "migration-nic"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  tags                = var.common_tags

  ip_configuration {
    name                          = "migration-ipconfig"
    subnet_id                     = azurerm_subnet.migration[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "migration_os" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                 = "migration-osdisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
  tags                 = var.common_tags
}

resource "azurerm_managed_disk" "migration_data" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                 = "migration-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_linux_virtual_machine" "migration" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                            = "migration-vm"
  location                        = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group[0].name
  network_interface_ids           = [azurerm_network_interface.migration[0].id]
  size                            = "Standard_D8ds_v5"
  tags                            = var.common_tags
  admin_username                  = var.admin_user
  admin_password                  = random_password.password.result
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
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
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  managed_disk_id    = azurerm_managed_disk.migration_data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.migration[0].id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "migration_aad" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration[0].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

resource "azurerm_key_vault_secret" "os_profile_password" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0
  name         = "os-profile-password"
  value        = random_password.password.result
  key_vault_id = module.darts_key_vault.key_vault_id
}

resource "azurerm_network_interface" "assessment" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                = "assessment-nic"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  tags                = var.common_tags

  ip_configuration {
    name                          = "assessment-ipconfig"
    subnet_id                     = azurerm_subnet.migration[0].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "assessment_windows" {
  count = contains(["stg", "prod"], var.env) ? 1 : 0 
  name                = "assessment-windows"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  size                = "Standard_D8ds_v5"
  tags                = var.common_tags
  admin_username      = var.admin_user
  admin_password      = random_password.password.result
  provision_vm_agent  = true
  computer_name       = "winAssessment"
  network_interface_ids = [
    azurerm_network_interface.assessment[0].id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "Windows-Assesment-OsDisk"
  }

  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-pro"
    version   = "latest"
  }
}