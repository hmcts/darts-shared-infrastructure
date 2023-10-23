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
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "255"
  tags                 = var.common_tags
}

resource "azurerm_windows_virtual_machine" "migration_windows" {
  for_each              = var.migration_vms
  name                  = each.key
  location              = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name   = azurerm_resource_group.darts_migration_resource_group.name
  size                  = "Standard_D16ds_v5"
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
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
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

resource "azurerm_linux_virtual_machine" "migration-linux" {
  name                            = "${var.env}dartsmigdb01"
  location                        = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group.name
  network_interface_ids           = [azurerm_network_interface.migration.id]
  size                            = var.env == "prd" ? "Standard_E32d_v5" : "Standard_D8ds_v5"
  tags                            = var.common_tags
  admin_username                  = var.admin_user
  admin_password                  = random_password.password.result
  disable_password_authentication = false
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Cannonical"
    offer     = "UbuntuServer"
    sku       = "22.04.03-LTS"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
}
resource "azurerm_managed_disk" "migration_disk" {
  name                 = "${var.env}darts_disk"
  location             = azurerm_resource_group.darts_migration_resource_group.location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "mig_datadisk" {
  managed_disk_id    = azurerm_managed_disk.migration_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.migration-linux.id
  lun                = "10"
  caching            = "ReadWrite"
}