
resource "azurerm_monitor_metric_alert" "blob-alert" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "blob-alert"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  scopes              = ["/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Storage/storageAccounts/saproddartsmig02"]
  description         = "Alert triggered when blob ingress drops below a threshold for 30 minutes"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Ingress"
    aggregation      = "Total"
    operator         = "LessThan"
    threshold        = 3221225472
  }

  action {
    action_group_id = azurerm_monitor_action_group.blob-action-group[0].id
  }

  tags = var.common_tags
}

resource "azurerm_monitor_action_group" "blob-action-group" {
  count               = local.is_migration_environment ? 1 : 0
  name                = "blob-ingress-action-group"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  short_name          = "alert-group"
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
resource "azurerm_monitor_metric_alert" "partition_capacity_alert_01" {
  name                = "partition-capacity-alert"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  scopes              = ["/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Compute/virtualMachines/prddartsmig01","/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/DARTS-MIGRATION-PROD-RG/providers/Microsoft.Compute/virtualMachines/prddartsmig02", "/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Compute/virtualMachines/prddartsmig03", "/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Compute/virtualMachines/prddartsmig04"]
  description         = "Alert triggered when a partition on the Windows VM reaches 80% capacity"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "LogicalDisk % Free Space"
    aggregation      = "Average"
    operator         = "LessThanOrEqual"
    threshold        = 20 # 100 - 80 (80% capacity)

    dimension {
      name     = "ResourceId"
      operator = "Include"
      values   = ["<vm-id>"]
    }
  }
}
  


  resource "azurerm_monitor_metric_alert" "partition_capacity_alert" {
  name                = "partition-capacity-alert"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  scopes              = ["/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Compute/virtualMachines/prddartsmig01","/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/DARTS-MIGRATION-PROD-RG/providers/Microsoft.Compute/virtualMachines/prddartsmig02", "/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Compute/virtualMachines/prddartsmig03", "/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Compute/virtualMachines/prddartsmig04", "/subscriptions/5ca62022-6aa2-4cee-aaa7-e7536c8d566c/resourceGroups/darts-migration-prod-rg/providers/Microsoft.Compute/virtualMachines/prddartsmig05"]
  description         = "Alert triggered when a partition on the Windows VM reaches 80% capacity"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThanOrEqual"
    threshold        = 107374182400

    dimension {
      name     = "ResourceId"
      operator = "Include"
      values   = ["<vm-id>"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.partition-capacity.id
  }

  tags = var.common_tags

}

resource "azurerm_monitor_action_group" "partition-capacity" {
  name                = "partition-space-group"
  resource_group_name = azurerm_resource_group.darts_migration_resource_group[0].name
  short_name          = "capacity"

  email_receiver {
    name                    = "email1"
    email_address           = "scott.robertson@hmcts.net"
    use_common_alert_schema = true
  }

  email_receiver {
    name                    = "Sean Bulley"
    email_address           = "sean.bulley@hmcts.net"
    use_common_alert_schema = true
  }
}