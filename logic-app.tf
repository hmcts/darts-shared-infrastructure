resource "azurerm_logic_app_workflow" "example" {
  name                = "example-logic-app"
  location            = azurerm_resource_group.darts_migration_resource_group[0].location
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name

  definition = <<DEFINITION
{
  "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
  "contentVersion": "1.0.0.0",
  "outputs": {},
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
    "Insert_into_PostgreSQL": {
      "type": "ExecuteStoredProcedure",
      "inputs": {
        "host": {
          "connection": {
            "name": "@parameters('$connections')['postgresql']['connectionId']"
          }
        },
        "method": "post",
        "path": "/v2/datasets/@{encodeURIComponent(encodeURIComponent(parameters('database_name')))}.executeStoredProcedure",
        "body": {
          "parameters": {
            "param1": "@triggerBody()['data']['properties']['fileName']"
          }
        }
      },
      "runAfter": {}
    }
  },
  "parameters": {
    "database_name": {
      "type": "string",
      "defaultValue": "your_database_name"
    }
  },
  "connections": {
    "postgresql": {
      "defaultValue": {},
      "type": "object"
    }
  }
}
DEFINITION
}

resource "azurerm_logic_app_trigger_eventgrid" "av-scan-trigger" {
  name               = "example-eventgrid-trigger"
  logic_app_id       = azurerm_logic_app_workflow.example.id
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name

  event_subscription {
    name                 = "av-scan-subscription"
    scope                = azurerm_eventgrid_topic.example.id
    subject_filter {
      subject_begins_with = ""
    }
    included_event_types = ["All"]
    webhook_endpoint {
      url = "https://<your-webhook-endpoint>"
    }
  }
}


resource "azurerm_eventgrid_event_subscription" "av-scanner-subscripton" {
  name                      = "av-scan-subscription"
  scope                     = azurerm_eventgrid_topic.example.id
  event_delivery_schema    = "EventGridSchema"
  included_event_types     = ["All"]
  webhook_endpoint {
    url = "https://your-webhook-endpoint.com"
  }
}