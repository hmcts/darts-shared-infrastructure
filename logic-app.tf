resource "azurerm_logic_app_workflow" "migration_scan" {
  name                = "example-logic-app"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name

  workflow_schema = <<EOF
{
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "contentVersion": "1.0.0.0",
    "triggers": {
        "manual": {
            "type": "Request",
            "kind": "Http",
            "inputs": {
                "schema": {}
            }
        }
    },
    "actions": {
        "Initialize_variable": {
            "inputs": {
                "variables": [
                    {
                        "name": "eventData",
                        "type": "Object",
                        "value": "@triggerBody()"
                    }
                ]
            },
            "runAfter": {},
            "type": "InitializeVariable"
        },
        "Execute_PowerShell_Script": {
            "inputs": {
                "body": {
                    "script": "Your PowerShell script here"
                },
                "headers": {
                    "Content-Type": "application/json"
                },
                "method": "POST",
                "uri": "<URL of your PowerShell script>"
            },
            "runAfter": {
                "Initialize_variable": [
                    "Succeeded"
                ]
            },
            "type": "Http"
        }
    },
    "outputs": {}
}
EOF
}

resource "azurerm_eventgrid_event_subscription" "mig-event-supscription" {
  name                  = "${var.product}-event-${var.env}-subscription"
  scope                 =  azurerm_resource_group.darts_migration_resource_group[0].id
  event_delivery_schema = "EventGridSchema"
  
}

