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

variable "component" {
  default = ""
}


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
  default = "Hot"
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
  default = "sds"
}
variable "application" {
  default = "core"
}
variable "admin_user" {
  default = "adminuser"
}

variable "hub" {
  type        = string
  description = "The hub environment to peer with."
  default     = "nonprod"
}

variable "address_space" {
  type    = string
  default = null
}

variable "postgres_subnet_address_space" {
  type    = string
  default = null
}

variable "extended_address_space" {
  type    = string
  default = null
}

variable "logic_apps_address_space" {
  type    = string
  default = null
}

variable "aks_subscription_id" {}

variable "virtual_machine_admins" {
  description = "List of pricipal IDs for the virtual machine administrators."
  type        = list(string)
  default     = []
}

variable "virtual_machine_users" {
  description = "List of pricipal IDs for the virtual machine users."
  type        = list(string)
  default     = []
}

variable "firewall_route_ranges" {
  type        = list(string)
  description = "List of address ranges to route to the DARTS specific migration firewall."
  default     = []
}


variable "storage_account_contributor_ids" {
  type        = list(string)
  description = "List of pricipal IDs to create a role assignemnt to grant the storage account contributor role."
  default     = []
}
variable "defender_enable" {
  type        = bool
  description = "boolean to enable microsoft defender"
  default     = false
}
variable "defender_scan" {
  type        = bool
  description = "boolean to enable microsoft defender scanning on incoming objects"
  default     = false
}

variable "migration_vms" {
  type = map(object({
    ip_address     = string
    subnet         = optional(string, "migration-subnet")
    data_disk_size = optional(string, "500")
    sku            = optional(string, "Standard_D16ds_v5")
    join_ad        = optional(bool, true)
    scope          = optional(string, "")
  }))
  description = "Map of objects describing the migration windows virtual machines to create."
  default     = {}
}
variable "modernisation_vms" {
  type = map(object({
    ip_address     = string
    subnet         = optional(string, "migration-subnet")
    data_disk_size = optional(string, "255")
    sku            = optional(string, "Standard_D16ds_v5")
    join_ad        = optional(bool, true)
  }))
  description = "Map of objects describing the modernisation windows virtual machines to create."
  default     = {}
}

variable "modernisation_vms_test" {
  type = map(object({
    subnet         = optional(string, "migration-subnet")
    data_disk_size = optional(string, "255")
    sku            = optional(string, "Standard_D16ds_v5")
    join_ad        = optional(bool, true)
  }))
  description = "Map of objects describing the modernisation windows virtual machines to create."
  default     = {}
}

variable "vm_subnet_id" {
  default = ""
}
variable "scope" {
  default = ""
}

variable "oracle_linux_vms" {
  type = map(object({
    ip_address = string
  }))
  description = "Map of objects describing the migration linux virtual machines to create."
  default     = {}
}
variable "migration_linux_vms" {
  type = map(object({
    ip_address = string
    subnet     = optional(string, "migration-subnet")
  }))
  description = "Map of objects describing the migration linux virtual machines to create."
  default     = {}
}
variable "migration_gitlab_vms" {
  type = map(object({
    ip_address = string
    subnet     = optional(string, "migration-subnet")
  }))
  description = "Map of objects describing the migration linux virtual machines to create."
  default     = {}
}

variable "migration_docker_vms" {
  type = map(object({
    ip_address = string
    subnet     = optional(string, "migration-subnet")
  }))
  description = "Map of objects describing the migration linux docker virtual machines to create."
  default     = {}
}

variable "modernisation_linux_vms" {
  type = map(object({
    sku = string
  }))
  description = "Map of objects describing the migration linux virtual machines to create."
  default     = {}
}
variable "migration_linux_vms2" {
  type = map(object({
    ip_address        = string
    availability_zone = string
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

variable "maxmemory_reserved" {
  default     = "642"
  description = "The maxmemory_reserved setting for the Redis cache"
}

variable "maxfragmentationmemory_reserved" {
  default     = "642"
  description = "The maxfragmentationmemory_reserved setting for the Redis cache"
}

variable "palo_networks" {
  type = map(object({
    address_space        = string
    enable_ip_forwarding = optional(bool, false)
    public_ip_required   = optional(bool, false)
    nsg_rules = optional(map(object({
      name_override                              = optional(string)
      priority                                   = number
      direction                                  = string
      access                                     = string
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(list(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(list(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string))
      source_application_security_group_ids      = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
      description                                = optional(string)
    })), {})
    nsg_deny_inbound = optional(bool, false)
  }))
  default     = {}
  description = "Describes the networks and associated resources to support the Palo Alto Firewall."
}

variable "max-file-upload-megabytes" {
  type        = number
  default     = "350"
  description = "The file upload size threshold in megabytes "
}

variable "max-file-upload-request-megabytes" {
  type        = number
  default     = "360"
  description = "The file upload request size threshold in megabytes "
}
variable "log_analytics_subscription_id" {}
variable "log_analytics_workspace_name" {}
variable "log_analytics_workspace_rg" {}

variable "default_action" {
  description = "Whether to block public access to the storage account"
  default     = "Deny"
}


variable "install_splunk_uf" {
  type        = bool
  description = "Install splunk uniforwarder on the virtual machine."
  default     = false
}

variable "splunk_username" {
  type    = string
  default = ""
}
variable "splunk_password" {
  type        = string
  description = "Splunk password"
  sensitive   = true
  default     = ""
}

variable "install_dynatrace_oneagent" {
  type        = bool
  description = "Install dynatrace agent on the virtual machine."
  default     = false
}

variable "install_nessus_agent" {
  type        = bool
  description = "Install nessus agent on the virtual machine."
  default     = false
}

variable "install_azure_monitor" {
  type        = bool
  description = "Install Azure Monitor Agent on the virtual machine."
  default     = false
}

variable "enable_sftp" {
  type        = bool
  description = "Enable storage account SFTP"
  default     = false
}

variable "install_endpoint_protection" {
  type        = bool
  description = "Install endpoint protection extension"
  default     = false
}
