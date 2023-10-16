resource "azurerm_network_interface" "migration_vms" {
  for_each            = var.migration_vms
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group.name
  tags                = var.common_tags

  ip_configuration {
    name                          = "migration-ipconfig"
    subnet_id                     = azurerm_subnet.migration.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip_address
  }
}

resource "azurerm_managed_disk" "migration_vms_data" {
  for_each             = var.migration_vms
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_windows_virtual_machine" "migration_windows" {
  for_each              = var.migration_vms
  name                  = each.key
  location              = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name   = azurerm_resource_group.darts_migration_resource_group.name
  size                  = "Standard_D8ds_v5"
  tags                  = var.common_tags
  admin_username        = var.admin_user
  admin_password        = random_password.password.result
  provision_vm_agent    = true
  computer_name         = each.key
  network_interface_ids = [azurerm_network_interface.migration_vms[each.key].id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${each.key}-OsDisk"
  }

  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-pro"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "migration_vms_datadisk" {
  for_each           = var.migration_vms
  managed_disk_id    = azurerm_managed_disk.migration_vms_data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.migration_windows[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}
