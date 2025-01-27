resource "azurerm_network_interface" "migration_vms" {
  for_each            = var.migration_vms
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

resource "azurerm_managed_disk" "migration_vms_data" {
  for_each             = var.migration_vms
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = each.value.data_disk_size
  tags                 = var.common_tags
}

resource "azurerm_windows_virtual_machine" "migration_windows" {
  for_each              = var.migration_vms
  name                  = each.key
  location              = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name   = azurerm_resource_group.darts_migration_resource_group[0].name
  size                  = each.value.sku
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
  identity {
    type = "SystemAssigned"
  }
}

module "vm-bootstrap-migration_vms" {
  providers = {
    azurerm.cnp = azurerm.cnp
    azurerm.soc = azurerm.soc
    azurerm.dcr = azurerm.dcr
  }

  for_each = var.migration_vms
  source   = "git@github.com:hmcts/terraform-module-vm-bootstrap?ref=master"

  virtual_machine_type        = "vm"
  virtual_machine_id          = azurerm_windows_virtual_machine.migration_windows[each.key].id
  install_splunk_uf           = var.install_splunk_uf
  splunk_username             = var.splunk_username
  splunk_password             = var.splunk_password
  install_nessus_agent        = var.install_nessus_agent
  os_type                     = "Windows"
  env                         = var.env
  install_dynatrace_oneagent  = var.install_dynatrace_oneagent
  common_tags                 = var.common_tags
  install_endpoint_protection = var.install_endpoint_protection

  install_azure_monitor = var.install_azure_monitor
}

resource "azurerm_virtual_machine_extension" "migration_windows_joinad" {
  for_each             = { for key, value in var.migration_vms : key => value if value.join_ad == true }
  name                 = "${each.key}-joinad"
  virtual_machine_id   = azurerm_windows_virtual_machine.migration_windows[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  settings             = <<SETTINGS
    {
        "Name": "HMCTS.NET",
        "OUPath": "OU=DARTS-Migration,DC=hmcts,DC=net",
        "User": "HMCTS\\${data.azurerm_key_vault_secret.aadds_username.value}",
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

resource "azurerm_virtual_machine_data_disk_attachment" "migration_vms_datadisk" {
  for_each           = var.migration_vms
  managed_disk_id    = azurerm_managed_disk.migration_vms_data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.migration_windows[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_network_interface" "migration-linux-nic" {
  for_each            = var.migration_linux_vms
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

resource "azurerm_linux_virtual_machine" "migration-linux" {
  for_each                        = var.migration_linux_vms
  name                            = each.key
  location                        = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group[0].name
  network_interface_ids           = [azurerm_network_interface.migration-linux-nic[each.key].id]
  size                            = "Standard_E32ds_v5"
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
module "vm-bootstrap-migration_linux_vms" {
  providers = {
    azurerm.cnp = azurerm.cnp
    azurerm.soc = azurerm.soc
    azurerm.dcr = azurerm.dcr
  }

  for_each = var.migration_linux_vms
  source   = "git@github.com:hmcts/terraform-module-vm-bootstrap?ref=master"

  virtual_machine_type        = "vm"
  virtual_machine_id          = azurerm_linux_virtual_machine.migration-linux[each.key].id
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

resource "azurerm_virtual_machine_extension" "migration-linux-aad" {
  for_each                   = var.migration_linux_vms
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration-linux[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

resource "azurerm_managed_disk" "migration_disk" {
  for_each             = var.migration_linux_vms
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "mig_datadisk" {
  for_each           = var.migration_linux_vms
  managed_disk_id    = azurerm_managed_disk.migration_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.migration-linux[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_network_interface" "migration-linux-nic2" {
  for_each            = var.migration_linux_vms2
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

resource "azurerm_linux_virtual_machine" "migration-linux2" {
  for_each                        = var.migration_linux_vms2
  name                            = each.key
  location                        = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group[0].name
  network_interface_ids           = [azurerm_network_interface.migration-linux-nic2[each.key].id]
  size                            = "Standard_E32ds_v5"
  tags                            = var.common_tags
  admin_username                  = var.admin_user
  admin_password                  = random_password.password.result
  disable_password_authentication = false
  zone                            = each.value.availability_zone
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

module "vm-bootstrap-migration_linux_vms2" {
  providers = {
    azurerm.cnp = azurerm.cnp
    azurerm.soc = azurerm.soc
    azurerm.dcr = azurerm.dcr
  }

  for_each = var.migration_linux_vms2
  source   = "git@github.com:hmcts/terraform-module-vm-bootstrap?ref=master"

  virtual_machine_type        = "vm"
  virtual_machine_id          = azurerm_linux_virtual_machine.migration-linux2[each.key].id
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

resource "azurerm_virtual_machine_extension" "migration-linux2-aad" {
  for_each                   = var.migration_linux_vms2
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.migration-linux2[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

resource "azurerm_managed_disk" "migration_disk2" {
  for_each             = var.migration_linux_vms2
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  zone                 = each.value.availability_zone
  tags                 = var.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "mig_datadisk2" {
  for_each           = var.migration_linux_vms2
  managed_disk_id    = azurerm_managed_disk.migration_disk2[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.migration-linux2[each.key].id
  lun                = "10"
  caching            = "ReadWrite"

}

resource "azurerm_linux_virtual_machine" "oracle" {
  for_each                        = var.oracle_linux_vms
  name                            = each.key
  location                        = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group[0].name
  network_interface_ids           = [azurerm_network_interface.oracle-linux-nic[each.key].id]
  size                            = "Standard_D4ds_v5"
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
    sku       = "7.7"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "oracle-aad" {
  for_each                   = var.oracle_linux_vms
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.oracle[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = var.common_tags
}

resource "azurerm_managed_disk" "oracle_disk" {
  for_each             = var.oracle_linux_vms
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "8000"
  tags                 = var.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "oracle_datadisk" {
  for_each           = var.oracle_linux_vms
  managed_disk_id    = azurerm_managed_disk.oracle_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.oracle[each.key].id
  lun                = "10"
  caching            = "None"
}

resource "azurerm_network_interface" "oracle-linux-nic" {
  for_each            = var.oracle_linux_vms
  name                = "${each.key}-nic"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  tags                = var.common_tags

  ip_configuration {
    name                          = "oracle-ipconfig"
    subnet_id                     = azurerm_subnet.migration[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip_address
  }
}

resource "azurerm_network_interface" "docker-linux-nic" {
  for_each            = var.migration_docker_vms
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

resource "azurerm_linux_virtual_machine" "dock-linux" {
  for_each                        = var.migration_docker_vms
  name                            = each.key
  location                        = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name             = azurerm_resource_group.darts_migration_resource_group[0].name
  network_interface_ids           = [azurerm_network_interface.docker-linux-nic[each.key].id]
  size                            = "Standard_E32ds_v5"
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
module "vm-bootstrap-migration_docker_vms" {
  providers = {
    azurerm.cnp = azurerm.cnp
    azurerm.soc = azurerm.soc
    azurerm.dcr = azurerm.dcr
  }

  for_each = var.migration_docker_vms
  source   = "git@github.com:hmcts/terraform-module-vm-bootstrap?ref=master"

  virtual_machine_type        = "vm"
  virtual_machine_id          = azurerm_linux_virtual_machine.dock-linux[each.key].id
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
resource "azurerm_managed_disk" "dock_disk" {
  for_each             = var.migration_docker_vms
  name                 = "${each.key}-datadisk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "200"
  tags                 = var.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "dock_datadisk" {
  for_each           = var.migration_docker_vms
  managed_disk_id    = azurerm_managed_disk.dock_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.dock-linux[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}


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
  virtual_machine_id         = azurerm_linux_virtual_machine.gitlab-linux[each.key].id
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
  disk_size_gb         = "500"
  tags                 = var.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "gitlab_datadisk" {
  for_each           = var.migration_gitlab_vms
  managed_disk_id    = azurerm_managed_disk.gitlab_disk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.gitlab-linux[each.key].id
  lun                = "10"
  caching            = "ReadWrite"
}

locals {
  first_5_vms = {
    for key in slice(
      keys(var.migration_vms),
      0,
      min(length(keys(var.migration_vms)), 5)
    ) : key => var.migration_vms[key]
  }
}

# Shared Managed Disk
resource "azurerm_managed_disk" "shared_disk" {
  name                 = "shared-disk"
  location             = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name  = azurerm_resource_group.darts_migration_resource_group[0].name
  storage_account_type = "Premium_LRS" # Ensure shared disk support
  disk_size_gb         = 1999
  max_shares           = 5 # Number of VMs sharing this disk
  create_option        = "Empty"
}

resource "azurerm_virtual_machine_data_disk_attachment" "shared_disk_attachment" {
  for_each           = local.first_5_vms
  managed_disk_id    = azurerm_managed_disk.shared_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.migration_windows[each.key].id
  lun                = 0
  caching            = "ReadWrite"
}