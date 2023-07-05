resource "azurerm_role_assignment" "bastion-admin" {
  provider           = azurerm.bastion
  scope              = data.azurerm_linux_virtual_machine.migration.id
  role_definition_id = var.aad_role_def_id_admin
  principal_id       = data.azuread_group.bastion-admin.id
}

resource "azurerm_role_assignment" "bastion-user" {
  provider           = azurerm.bastion
  scope              = data.azurerm_linux_virtual_machine.migration.id
  role_definition_id = var.aad_role_def_id_user
  principal_id       = data.azuread_group.bastion-user.id
}

provider "azurerm" {
  version = ">= 3.4.0"
  features {}
  subscription_id = var.bastion_subscription_id
  alias           = "bastion"
}