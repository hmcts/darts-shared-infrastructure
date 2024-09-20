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



module "vm-bootstrap" {
  providers = {
    azurerm.cnp = azurerm.cnp
    azurerm.soc = azurerm.soc
    azurerm.dcr = azurerm.dcr
  }

  count  = local.is_migration_environment ? 1 : 0
  source = "git@github.com/hmcts/terraform-module-vm-bootstrap.git?ref=ieuanb74-patch-1"

  virtual_machine_type       = "vm"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration[0].id
  install_splunk_uf          = var.install_splunk_uf
  splunk_username            = var.splunk_username
  splunk_password            = var.splunk_password
  install_nessus_agent       = var.install_nessus_agent
  os_type                    = "Linux"
  env                        = var.env
  install_dynatrace_oneagent = var.install_dynatrace_oneagent
  common_tags                = var.common_tags

  install_azure_monitor = var.install_azure_monitor
}
