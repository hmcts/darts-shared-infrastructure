
resource "azurerm_network_interface" "gitlab-linux-nic" {
  for_each            = var.migration_gitlab_vms
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  tags                = var.common_tags

  ip_configuration {
    name                          = "migration-ipconfig"
    subnet_id                     = each.value.subnet == "migration-subnet" ? azurerm_subnet.migration[0].id : azurerm_subnet.migration-extended[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip_address
  }
}

resource "azurerm_linux_virtual_machine" "gitlab-linux" {
  for_each                        = var.migration_gitlab_vms
  name                            = each.key
  location                        = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group[0].name
  network_interface_ids           = [azurerm_network_interface.gitlab-linux-nic[each.key].id]
  size                            = "Standard_D4s_v3"
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
module "vm-bootstrap-migration_gitlab_vms" {
  providers = {
    azurerm.cnp = azurerm.cnp
    azurerm.soc = azurerm.soc
    azurerm.dcr = azurerm.dcr
  }

  for_each = var.migration_gitlab_vms
  source   = "git@github.com:hmcts/terraform-module-vm-bootstrap?ref=master"

  virtual_machine_type        = "vm"
  virtual_machine_id          = azurerm_linux_virtual_machine.gitlab-linux[each.key].id
  install_splunk_uf           = var.install_splunk_uf
  splunk_username             = var.splunk_username
  splunk_password             = var.splunk_password
  install_nessus_agent        = var.install_nessus_agent
  os_type                     = "Linux"
  env                         = var.env
  install_dynatrace_oneagent  = var.install_dynatrace_oneagent
  common_tags                 = var.common_tags
  install_endpoint_protection = var.install_endpoint_protection
  install_azure_monitor       = var.install_azure_monitor
}

resource "azurerm_virtual_machine_extension" "gitlab-linux-aad" {
  for_each                   = var.migration_gitlab_vms
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration-linux[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

resource "azurerm_managed_disk" "gitlab_disk" {
  for_each             = var.migration_gitlab_vms
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "gitlab_datadisk" {
  for_each           = var.migration_gitlab_vms
  managed_disk_id    = azurerm_managed_disk.migration_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.migration-linux[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}