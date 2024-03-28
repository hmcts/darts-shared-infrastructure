# resource "azurerm_logic_app_workflow" "example" {
#   name                = "example-logic-app"
#   location            = azurerm_resource_group.darts_migration_resource_group[0].location
#   resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name

#   definition = 
# {
#     "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
#     "contentVersion": "1.0.0.0",
#     "triggers": {
#         "manual": {
#             "type": "Request",
#             "kind": "Http",
#             "inputs": {
#                 "schema": {}
#             }
#         }
#     },
#     "actions": {
#         "Initialize_variable": {
#             "inputs": {
#                 "variables": [
#                     {
#                         "name": "eventData",
#                         "type": "Object",
#                         "value": "@triggerBody()"
#                     }
#                 ]
#             },
#             "runAfter": {},
#             "type": "InitializeVariable"
#         },
#         "Respond_to_HTTP_request": {
#             "inputs": {
#                 "body": {
#                     "message": "Hello from Logic App triggered by Event Grid!"
#                 },
#                 "headers": {
#                     "Content-Type": "application/json"
#                 },
#                 "statusCode": 200
#             },
#             "runAfter": {
#                 "Initialize_variable": [
#                     "Succeeded"
#                 ]
#             },
#             "type": "Response"
#         }
#     },
#     "outputs": {}
# }
# EOF
# }

# resource "azurerm_logic_app_trigger_eventgrid" "av-scan-trigger" {
#   name               = "example-eventgrid-trigger"
#   logic_app_id       = azurerm_logic_app_workflow.example.id
#   resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name

#   event_subscription {
#     name                 = "av-scan-subscription"
#     scope                = azurerm_eventgrid_topic.example.id
#     subject_filter {
#       subject_begins_with = ""
#     }
#     included_event_types = ["All"]
#     webhook_endpoint {
#       url = "https://<your-webhook-endpoint>"
#     }
#   }
# }


# resource "azurerm_eventgrid_event_subscription" "av-scanner-subscripton" {
#   name                      = "av-scan-subscription"
#   scope                     = azurerm_eventgrid_topic.example.id
#   event_delivery_schema    = "EventGridSchema"
#   included_event_types     = ["All"]
#   webhook_endpoint {
#     url = "https://your-webhook-endpoint.com"
#   }
# }