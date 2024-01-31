resource "azurerm_network_interface" "migration" {
  count               = local.is_migration_environment ? 1 : 0
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

moved {
  from = azurerm_network_interface.migration
  to   = azurerm_network_interface.migration[0]
}

resource "azurerm_managed_disk" "migration_os" {
  count                = local.is_migration_environment ? 1 : 0
  name                 = "migration-osdisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
  tags                 = var.common_tags
}

moved {
  from = azurerm_managed_disk.migration_os
  to   = azurerm_managed_disk.migration_os[0]
}

resource "azurerm_managed_disk" "migration_data" {
  count                = local.is_migration_environment ? 1 : 0
  name                 = "migration-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

moved {
  from = azurerm_managed_disk.migration_data
  to   = azurerm_managed_disk.migration_data[0]
}

resource "azurerm_linux_virtual_machine" "migration" {
  count                           = local.is_migration_environment ? 1 : 0
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

moved {
  from = azurerm_linux_virtual_machine.migration
  to   = azurerm_linux_virtual_machine.migration[0]
}

resource "azurerm_virtual_machine_data_disk_attachment" "datadisk" {
  count              = local.is_migration_environment ? 1 : 0
  managed_disk_id    = azurerm_managed_disk.migration_data[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.migration[0].id
  lun                = "10"
  caching            = "ReadWrite"
}

moved {
  from = azurerm_virtual_machine_data_disk_attachment.datadisk
  to   = azurerm_virtual_machine_data_disk_attachment.datadisk[0]
}

resource "azurerm_virtual_machine_extension" "migration_aad" {
  count                      = local.is_migration_environment ? 1 : 0
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration[0].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

moved {
  from = azurerm_virtual_machine_extension.migration_aad
  to   = azurerm_virtual_machine_extension.migration_aad[0]
}

resource "azurerm_key_vault_secret" "os_profile_password" {
  count        = local.is_migration_environment ? 1 : 0
  name         = "os-profile-password"
  value        = random_password.password.result
  key_vault_id = module.darts_key_vault.key_vault_id
}

moved {
  from = azurerm_key_vault_secret.os_profile_password
  to   = azurerm_key_vault_secret.os_profile_password[0]
}

resource "azurerm_network_interface" "assessment" {
  count               = local.is_migration_environment ? 1 : 0
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

moved {
  from = azurerm_network_interface.assessment
  to   = azurerm_network_interface.assessment[0]
}

resource "azurerm_windows_virtual_machine" "assessment_windows" {
  count               = local.is_migration_environment ? 1 : 0
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

moved {
  from = azurerm_windows_virtual_machine.assessment_windows
  to   = azurerm_windows_virtual_machine.assessment_windows[0]
}

resource "azurerm_virtual_machine_extension" "assessment_windows_joinad" {
  count                = local.is_migration_environment ? 1 : 0
  name                 = "assessment-windows-joinad"
  virtual_machine_id   = azurerm_windows_virtual_machine.assessment_windows[0].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  settings             = <<SETTINGS
    {
        "Name": "HMCTS.NET",
        "OUPath": "OU=DARTS-Migration,DC=hmcts,DC=net",
        "User": "HMCTS\${data.azurerm_key_vault_secret.aadds_username.value}",
        "Restart": "true",
        "Options": "3"
    }
  SETTINGS
  protected_settings   = <<PROTECTED_SETTINGS
    {
      "Password": "${data.azurerm_key_vault_secret.aadds_password.value}"
    }
  PROTECTED_SETTINGS

  tags = var.common_tags
}
