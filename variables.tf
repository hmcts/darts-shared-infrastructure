variable "common_tags" {
  type = map(string)
}

variable "env" {
  description = "The deployment environment (sandbox, aat, prod etc..)"
}

variable "jenkins_AAD_objectId" {
  description = "The object ID of the user to be granted access to the key vault"
}

variable "location" {
  description = "The location where you would like to deploy your infrastructure"
  default     = "UK South"
}

variable "product" {}

variable "component" {}


variable "project" {
  description = "Project name"
  default     = "sds"
}
variable "containers" {
  type = list(object({
    name        = string
    access_type = string
  }))
  description = "List of Storage Containers"
  default     = []
}

variable "resource_group_name" {
  default = ""
}
variable "storage_container_name" {
  default = "darts"
}
## SA Defaults
variable "sa_access_tier" {
  type    = string
  default = "Cool"
}
variable "sa_account_kind" {
  type    = string
  default = "StorageV2"
}
variable "sa_account_tier" {
  type    = string
  default = "Standard"
}
variable "sa_mig_account_tier" {
  type    = string
  default = "Premium"
}
variable "sa_mig_account_kind" {
  type    = string
  default = "BlockBlobStorage"
}

variable "sa_account_replication_type" {
  type    = string
  default = "RAGRS"
}
variable "sa_mig_account_replication_type" {
  type    = string
  default = "ZRS"
}
variable "ip_range" {
  type    = list(string)
  default = ["10.24.239.0/28"]
}

variable "windows_machines" {
  type    = list(string)
  default = ["win-migration-1", "win-migration-2", "win-migration-3", "win-migration-4", "win-migration-5"]
}

variable "builtFrom" {
  type    = string
  default = "https://github.com/hmcts/darts-shared-infrastructure.git"
}
variable "businessArea" {
  default = "Cross-Cutting"
}
variable "application" {
  default = "core"
}
variable "admin_user" {
  default = "adminuser"
}
variable "hub" {}

variable "address_space" {}

variable "firewall_address_space" {}

variable aks_subscription_id {}

variable "virtual_machine_admins" {
  description = "List of pricipal IDs for the virtual machine administrators."
  type        = list(string)
}

variable "virtual_machine_users" {
  description = "List of pricipal IDs for the virtual machine users."
  type        = list(string)
}

variable "firewall_policy_priority" {
  description = "The priority of the firewall policy."
  type        = number
  default     = 100
}

variable "firewall_application_rules" {
  type = map(object({
    action   = string
    priority = number
    rules = optional(map(object({
      description = optional(string)
      protocols = list(object({
        port = number
        type = string
      }))
      source_addresses      = optional(list(string), [])
      destination_addresses = optional(list(string), [])
      source_ip_groups      = optional(list(string), [])
      destination_fqdns     = optional(list(string), [])
    })), {})
  }))
  description = "Map of firewall application rule collections to create with any number of related rules."
  default     = {}
}

variable "firewall_network_rules" {
  type = map(object({
    action   = string
    priority = number
    rules = optional(map(object({
      protocols             = list(string)
      source_addresses      = optional(list(string), [])
      source_ip_groups      = optional(list(string), [])
      destination_addresses = optional(list(string), [])
      destination_ip_groups = optional(list(string), [])
      destination_fqdns     = optional(list(string), [])
      destination_ports     = list(string)
    })), {})
  }))
  description = "Map of firewall network rule collections to create with any number of related rules."
  default     = {}
}

variable "firewall_nat_rules" {
  type = map(object({
    action   = string
    priority = number
    rules = optional(map(object({
      protocols          = list(string)
      source_addresses   = optional(list(string), [])
      source_ip_groups   = optional(list(string), [])
      destination_ports  = optional(list(string), [])
      translated_address = optional(string)
      translated_fqdn    = optional(string)
      translated_port    = number
    })), {})
  }))
  description = "Map of firewall NAT rule collections to create with any number of related rules."
  default     = {}
}

variable "az_firewall_route_ranges" {
  type        = list(string)
  description = "List of IP ranges to route through the firewall."
  default = [
    "10.23.253.177/32",
    "10.23.253.178/32",
    "10.23.253.241/32",
    "10.23.253.242/32",
    "10.23.253.243/32",
    "10.23.253.244/32",
    "10.63.111.175/32",
    "10.63.111.187/32",
    "10.63.111.176/32",
    "10.63.111.188/32",
    "10.65.64.155/32",
    "10.65.64.180/32",
    "10.65.64.156/32",
    "10.65.64.181/32"
  ]
}

variable "firewall_log_analytics_enabled" {
  type        = bool
  description = "Enable firewall logging to log analytics."
  default     = false
}

variable "storage_account_contributor_ids" {
  type        = list(string)
  description = "List of pricipal IDs to create a role assignemnt to grant the storage account contributor role."
  default     = []
}


variable "migration_vms" {
  type = map(object({
    ip_address = string
  }))
  description = "Map of objects describing the migration windows virtual machines to create."
  default     = {}
}

variable "migration_linux_vms" {
  type = map(object({
    ip_address = string
  }))
  description = "Map of objects describing the migration linux virtual machines to create."
  default     = {}
}
variable "family" {
  default     = "C"
  description = "The SKU family/pricing group to use. Valid values are `C` (for Basic/Standard SKU family) and `P` (for Premium). Use P for higher availability, but beware it costs a lot more."
}

variable "sku_name" {
  default     = "Basic"
  description = "The SKU of Redis to use. Possible values are `Basic`, `Standard` and `Premium`."
}

variable "capacity" {
  default     = "1"
  description = "The size of the Redis cache to deploy. Valid values are 1, 2, 3, 4, 5"
}
