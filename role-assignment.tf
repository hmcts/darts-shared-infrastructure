resource "azurerm_role_assignment" "vm-admin" {
  for_each = contains(["stg", "prod"], var.env) ? length(var.virtual_machine_admins) : {}
  scope                = azurerm_linux_virtual_machine.migration[each.key].id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = var.virtual_machine_admins[count.index]
}

resource "azurerm_role_assignment" "vm-user" {
  for_each = contains(["stg", "prod"], var.env) ? length(var.virtual_machine_users) : {}
  scope                = azurerm_linux_virtual_machine.migration[each.key].id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = var.virtual_machine_users[count.index]
}
