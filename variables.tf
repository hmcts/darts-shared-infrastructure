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


variable "account_kind"{
  default     = ""
}

variable "resource_group_name"{
  default     = ""
}
