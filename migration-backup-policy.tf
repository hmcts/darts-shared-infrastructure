
resource "azurerm_recovery_services_vault" "darts-migration-backup" {
  name                = "darts-prod-rsv"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "darts-migration-backup" {
  name                = "darts-prod-policy"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  recovery_vault_name = azurerm_recovery_services_vault.darts-migration-backup.name

  timezone = "GMT Standard Time"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_vm" "vm" {
  for_each            = var.migration_vms
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  recovery_vault_name = azurerm_recovery_services_vault.darts-migration-backup.name
  source_vm_id        = azurerm_windows_virtual_machine.migration_windows[each.key].id
  backup_policy_id    = azurerm_backup_policy_vm.darts-migration-backup.id
}

resource "azurerm_backup_protected_vm" "oracle" {
  for_each            = var.oracle_linux_vms
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  recovery_vault_name = azurerm_recovery_services_vault.darts-migration-backup.name
  source_vm_id        = azurerm_linux_virtual_machine.oracle[each.key].id
  backup_policy_id    = azurerm_backup_policy_vm.darts-migration-backup.id
}

resource "azurerm_backup_protected_vm" "mig1" {
  for_each            = var.migration_linux_vms
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  recovery_vault_name = azurerm_recovery_services_vault.darts-migration-backup.name
  source_vm_id        = azurerm_linux_virtual_machine.migration-linux[each.key].id
  backup_policy_id    = azurerm_backup_policy_vm.darts-migration-backup.id
}

resource "azurerm_backup_protected_vm" "mig2" {
  for_each            = var.oracle_linux_vms
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  recovery_vault_name = azurerm_recovery_services_vault.darts-migration-backup.name
  source_vm_id        = azurerm_linux_virtual_machine.migration-linux2[each.key].id
  backup_policy_id    = azurerm_backup_policy_vm.darts-migration-backup.id
}