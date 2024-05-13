
resource "azurerm_monitor_metric_alert" "example" {
  name                = "blob-alert"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  scopes              = ["/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Storage/storageAccounts/saproddartsmig02"]
  description         = "Alert triggered when blob ingress drops below a threshold for 30 minutes"
  enabled             = true

  criteria {
    metric_namespace  = "Microsoft.Storage/storageAccounts"
    metric_name       = "BlobIngress"
    aggregation       = "Average"
    operator          = "LessThan"
    threshold         = 96636764160  # Adjust the threshold as per your requirement
    # window_size       = "PT30M"
    # time_aggregation  = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.blob-action-group.id
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_monitor_action_group" "blob-action-group" {
  name                = "blob-ingress-action-group"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  short_name          = "example"
  email_receiver {
    name                    = "Sean Bulley"
    email_address           = "sean.bulley@hmcts.net"
    use_common_alert_schema = true
  }
  email_receiver {
    name                    = "Scott Robertson"
    email_address           = "scott.robertson@hmcts.net"
    use_common_alert_schema = true
  }
}
