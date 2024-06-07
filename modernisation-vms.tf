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


# resource "azurerm_network_interface" "modernisation_vms_test" {
#   for_each            = var.modernisation_vms_test
#   name                = "${each.key}-nic"
#   location            = azurerm_resource_group.darts_resource_group.location
#   resource_group_name = azurerm_resource_group.darts_resource_group.name
#   tags                = var.common_tags

#   ip_configuration {
#     name                          = "privateIPAddress"
#     subnet_id                     = var.vm_subnet_id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# resource "azurerm_managed_disk" "modernisation_vms_data_test" {
#   for_each             = var.modernisation_vms_test
#   name                 = "${each.key}-datadisk"
#   location             = azurerm_resource_group.darts_resource_group.location
#   resource_group_name  = azurerm_resource_group.darts_resource_group.name
#   storage_account_type = "Premium_LRS"
#   create_option        = "Empty"
#   disk_size_gb         = each.value.data_disk_size
#   tags                 = var.common_tags
# }

# resource "azurerm_windows_virtual_machine" "modernisation_windows_test" {
#   for_each              = var.modernisation_vms_test
#   name                  = each.key
#   location              = azurerm_resource_group.darts_resource_group.location
#   resource_group_name   = azurerm_resource_group.darts_resource_group.name
#   size                  = each.value.sku
#   tags                  = var.common_tags
#   admin_username        = var.admin_user
#   admin_password        = random_password.password.result
#   provision_vm_agent    = true
#   computer_name         = each.key
#   network_interface_ids = [azurerm_network_interface.modernisation_vms_test[each.key].id]
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#     name                 = "${each.key}-OsDisk"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2022-Datacenter"
#     version   = "latest"
#   }
# }



# resource "azurerm_virtual_machine_data_disk_attachment" "modernisation_vms_datadisk_test" {
#   for_each           = var.modernisation_vms_test
#   managed_disk_id    = azurerm_managed_disk.modernisation_vms_data_test[each.key].id
#   virtual_machine_id = azurerm_windows_virtual_machine.modernisation_windows_test[each.key].id
#   lun                = "10"
#   caching            = "ReadWrite"
# }




# resource "azurerm_network_interface" "modernisation-linux-nic" {
#   for_each            = var.modernisation_linux_vms
#   name                = "${each.key}-nic"
#   location            = azurerm_resource_group.darts_resource_group.location
#   resource_group_name = azurerm_resource_group.darts_resource_group.name
#   tags                = var.common_tags

#   ip_configuration {
#     name                          = "privateIPAddress"
#     subnet_id                     = var.vm_subnet_id
#     private_ip_address_allocation = "Dynamic"
#   }
# }

# resource "azurerm_linux_virtual_machine" "modernisation-linux" {
#   for_each                        = var.modernisation_linux_vms
#   name                            = each.key
#   location                        = azurerm_resource_group.darts_resource_group.location
#   resource_group_name             = azurerm_resource_group.darts_resource_group.name
#   network_interface_ids           = [azurerm_network_interface.modernisation-linux-nic[each.key].id]
#   size                            = "Standard_D4ds_v5"
#   tags                            = var.common_tags
#   admin_username                  = var.admin_user
#   admin_password                  = random_password.password.result
#   disable_password_authentication = false
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Premium_LRS"
#   }
#   source_image_reference {
#     publisher = "canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts-gen2"
#     version   = "latest"
#   }
#   identity {
#     type = "SystemAssigned"
#   }
# }

# resource "azurerm_managed_disk" "modernisation_disk" {
#   for_each             = var.modernisation_linux_vms
#   name                 = "${each.key}-datadisk"
#   location             = azurerm_resource_group.darts_resource_group.location
#   resource_group_name  = azurerm_resource_group.darts_resource_group.name
#   storage_account_type = "Premium_LRS"
#   create_option        = "Empty"
#   disk_size_gb         = "200"
#   tags                 = var.common_tags
# }

# resource "azurerm_virtual_machine_data_disk_attachment" "mod_datadisk" {
#   for_each           = var.modernisation_linux_vms
#   managed_disk_id    = azurerm_managed_disk.modernisation_disk[each.key].id
#   virtual_machine_id = azurerm_linux_virtual_machine.modernisation-linux[each.key].id
#   lun                = "10"
#   caching            = "ReadWrite"
# }
