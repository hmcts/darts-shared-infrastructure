resource "azurerm_role_assignment" "vm-admin" {
  count                = length(var.virtual_machine_admins)
  scope                = azurerm_linux_virtual_machine.migration.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = var.virtual_machine_admins[count.index]
}

variable "admin-users" {
  type = map(object({
    is_group               = optional(bool, false)
    group_security_enabled = optional(bool, false)
    is_user                = optional(bool, false)
    is_service_principal   = optional(bool, false)
    role_type              = string
  }))
  description = "Map of objects describing the users, groups and service principals who should be able to access the LDAP VMs."
  default     = {}
  validation {
    condition = alltrue([
      for user in var.admin-users : anytrue([user.is_group != null, user.is_user != null, user.is_service_principal != null])
      && contains(["admin", "user"], lower(user.role_type))
    ])
    error_message = "One of is_group, is_user or is_service_principal must be set to true for each user, group or service principal. The valid values for role_type are admin and user."
  }
}
data "azuread_group" "ldap_groups" {
  for_each         = { for key, value in var.admin-users : key => value if value.is_group == true }
  display_name     = each.key
  security_enabled = each.value.group_security_enabled
}
data "azuread_service_principal" "ldap_sps" {
  for_each     = { for key, value in var.admin-users : key => value if value.is_service_principal == true }
  display_name = each.key
}


resource "azurerm_role_assignment" "vm-admin2" {
for_each             = { for value in local.flattened_admin_users : "${value.user_key}-${value.vm_key}" => value }
  scope                = each.value.vm_id
  role_definition_name = each.value.user.role_type == "admin" ? "Virtual Machine Administrator Login" : "Virtual Machine User Login"
  principal_id         = each.value.user.is_user == true ? data.azuread_user.admin-users[each.value.user_key].id : each.value.user.is_group == true ? data.azuread_group.ldap_groups[each.value.user_key].id : data.azuread_service_principal.ldap_sps[each.value.user_key].id
}


resource "azurerm_role_assignment" "vm-user" {
  count                = length(var.virtual_machine_users)
  scope                = azurerm_linux_virtual_machine.migration.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = var.virtual_machine_users[count.index]
}
