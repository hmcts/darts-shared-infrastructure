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

variable "product" {
  description = "The name of your application"
  default     = "darts"
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



variable "resource_group_name"{
  default     = ""
}
variable "storage_container_name"{
  default     = "darts"
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

variable "ipAddress"{
  type  =string
  default = "00.00.000.0/00"
}
variable "ipRange"{
  type =list(string)
  default = ["00.00.000.0/00"]
}