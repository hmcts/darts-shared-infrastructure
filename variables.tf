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
variable "sa_account_replication_type" {
  type    = string
  default = "RAGRS"
}
variable "ip_range"{
  type =list(string)
  default = ["10.24.239.0/28"]
}
variable "ip_range_2"{
  type =list(string)
  default = ["10.24.239.48/28"]
}
variable "paloaltoProd"{
  default = "10.11.8.36/32"
}
variable "paloaltoNonProd"{
  default = "10.11.72.36/32" 
}

variable "builtFrom" {
  type = string
  default = "https://github.com/hmcts/darts-shared-infrastructure.git"
}
variable "businessArea" {
  default = "Cross-Cutting"
}
variable "application" {
  default = "core"
}
variable "admin_user"{
  default = "adminuser"
}
variable "hub" {}

