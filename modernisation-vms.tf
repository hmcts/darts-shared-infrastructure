resource "azurerm_network_interface" "modernisation_vms" {
  for_each            = var.modernisation_vms
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.darts_resource_group.location
  resource_group_name = azurerm_resource_group.darts_resource_group.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "migration-ipconfig"
    subnet_id                     = each.value.subnet == "migration-subnet" ? azurerm_subnet.migration[0].id : azurerm_subnet.migration-extended[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip_address
  }
}

resource "azurerm_managed_disk" "modernisation_vms_data" {
  for_each             = var.modernisation_vms
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_resource_group.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk_size
  tags                 = var.common_tags
}

resource "azurerm_windows_virtual_machine" "modernisation_windows" {
  for_each              = var.modernisation_vms
  name                  = each.key
  location              = azurerm_resource_group.darts_resource_group.location
  resource_group_name   = azurerm_resource_group.darts_resource_group.name
  size                  = each.value.sku
  tags                  = var.common_tags
  admin_username        = var.admin_user
  admin_password        = random_password.password.result
  provision_vm_agent    = true
  computer_name         = each.key
  network_interface_ids = [azurerm_network_interface.modernisation_vms[each.key].id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${each.key}-OsDisk"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}



resource "azurerm_virtual_machine_data_disk_attachment" "modernisation_vms_datadisk" {
  for_each           = var.modernisation_vms
  managed_disk_id    = azurerm_managed_disk.modernisation_vms_data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.modernisation_windows[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
  
}




resource "azurerm_network_interface" "modernisation-linux-nic" {
  for_each            = var.modernisation_linux_vms
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  tags                = var.common_tags

  ip_configuration {
    name                          = "migration-ipconfig"
    subnet_id                     = azurerm_subnet.migration[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip_address
  }
}

resource "azurerm_linux_virtual_machine" "modernisation-linux" {
  for_each                        = var.modernisation_linux_vms
  name                            = each.key
  location                        = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group[0].name
  network_interface_ids           = [azurerm_network_interface.migration-linux-nic[each.key].id]
  size                            = "Standard_D4ds_v5"
  tags                            = var.common_tags
  admin_username                  = var.admin_user
  admin_password                  = random_password.password.result
  disable_password_authentication = false
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
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

resource "azurerm_virtual_machine_extension" "modernisation-linux-aad" {
  for_each                   = var.modernisation_linux_vms
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration-linux[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

resource "azurerm_managed_disk" "modernisation_disk" {
  for_each             = var.modernisation_linux_vms
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "mod_datadisk" {
  for_each           = var.modernisation_linux_vms
  managed_disk_id    = azurerm_managed_disk.migration_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.migration-linux[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}