resource "azurerm_network_interface" "migration" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                = "migration-nic"
  location            = azurerm_resource_group.darts_migration_resource_group[each.key].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[each.key].name
  tags                = var.common_tags

  ip_configuration {
    name                          = "migration-ipconfig"
    subnet_id                     = azurerm_subnet.migration.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "migration_os" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                 = "migration-osdisk"
  location             = azurerm_resource_group.darts_migration_resource_group[each.key].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[each.key].name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
  tags                 = var.common_tags
}

resource "azurerm_managed_disk" "migration_data" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                 = "migration-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[each.key].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[each.key].name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_linux_virtual_machine" "migration" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                            = "migration-vm"
  location                        = azurerm_resource_group.darts_migration_resource_group[each.key].location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group[each.key].name
  network_interface_ids           = [azurerm_network_interface.migration.id]
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
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  managed_disk_id    = azurerm_managed_disk.migration_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.migration.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "migration_aad" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

resource "azurerm_key_vault_secret" "os_profile_password" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name         = "os-profile-password"
  value        = random_password.password.result
  key_vault_id = module.darts_key_vault.key_vault_id
}

resource "azurerm_network_interface" "assessment" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                = "assessment-nic"
  location            = azurerm_resource_group.darts_migration_resource_group[each.key].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[each.key].name
  tags                = var.common_tags

  ip_configuration {
    name                          = "assessment-ipconfig"
    subnet_id                     = azurerm_subnet.migration.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "assessment_windows" {
  for_each = contains(["stg", "prod"], var.env) ? var.create_resource : {}
  name                = "assessment-windows"
  location            = azurerm_resource_group.darts_migration_resource_group[each.key].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[each.key].name
  size                = "Standard_D8ds_v5"
  tags                = var.common_tags
  admin_username      = var.admin_user
  admin_password      = random_password.password.result
  provision_vm_agent  = true
  computer_name       = "winAssessment"
  network_interface_ids = [
    azurerm_network_interface.assessment.id,
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