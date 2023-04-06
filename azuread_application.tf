
resource "azuread_application" "app" {
  display_name = format("darts-%s-app", var.env)

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Role"
    }
  }

}

resource "azuread_application_password" "secret" {
  application_object_id = azuread_application.app.object_id
}