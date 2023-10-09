resource "azurerm_network_interface" "legacy" {
  name                = "legacy-nic"
  location            = azurerm_resource_group.darts_resource_group.location
  resource_group_name = azurerm_resource_group.darts_resource_group.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "legacy-ipconfig"
    subnet_id                     = azurerm_subnet.migration.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "legacy_os" {
  name                 = "legacy-osdisk"
  location             = azurerm_resource_group.darts_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
  tags                 = var.common_tags
}

resource "azurerm_managed_disk" "legacy_data" {
  name                 = "legacy-datadisk"
  location             = azurerm_resource_group.darts_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_linux_virtual_machine" "legacy" {
  name                            = "legacy-vm"
  location                        = azurerm_resource_group.darts_resource_group.location
  resource_group_name             = azurerm_resource_group.darts_resource_group.name
  network_interface_ids           = [azurerm_network_interface.legacy.id]
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
  managed_disk_id    = azurerm_managed_disk.legacy_data.id
  virtual_machine_id = azurerm_linux_virtual_machine.legacy.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "legacy_aad" {
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.legacy.id
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

resource "azurerm_network_interface" "assessment" {
  name                = "legacy-nic"
  location            = azurerm_resource_group.darts_resource_group.location
  resource_group_name = azurerm_resource_group.darts_resource_group.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "assessment-ipconfig"
    subnet_id                     = azurerm_subnet.migration.id
    private_ip_address_allocation = "Dynamic"
  }
}


