data "azurerm_resource_group" "darts_resource_group" {
  name = format("%s-%s-rg", var.product, var.env)
}

data "azurerm_subnet" "private_endpoints" {
  resource_group_name  = local.private_endpoint_rg_name
  virtual_network_name = local.private_endpoint_vnet_name
  name                 = "private-endpoints"
}

module "sa" {
  source = "git@github.com:hmcts/cnp-module-storage-account?ref=4.x"

  env = var.env

  storage_account_name = local.storage_account_name
  common_tags          = var.common_tags

  default_action = "Allow"

  resource_group_name = azurerm_resource_group.darts_resource_group.name
  location            = var.location

  account_tier                    = var.sa_account_tier
  account_kind                    = var.sa_account_kind
  account_replication_type        = var.sa_account_replication_type
  access_tier                     = var.sa_access_tier
  allow_nested_items_to_be_public = "true"
  enable_change_feed              = true
  private_endpoint_subnet_id      = data.azurerm_subnet.private_endpoints.id

  enable_data_protection = true

  containers = local.containers

  cors_rules = [{
    allowed_headers    = ["*"]
    allowed_methods    = ["GET", "OPTIONS"]
    allowed_origins    = ["https://hmctsdartsb2csbox.b2clogin.com"]
    exposed_headers    = ["*"]
    max_age_in_seconds = 200
  }]

}

resource "azurerm_storage_blob" "outbound" {
  name                   = "${var.product}-outbound-blob-st-${var.env}"
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"

  depends_on = [module.sa]
}

resource "azurerm_storage_blob" "unstructured" {
  name                   = "${var.product}-unstrcutured-blob-st-${var.env}"
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"

  depends_on = [module.sa]
}

resource "azurerm_storage_blob" "inbound" {
  name                   = "${var.product}-inbound-blob-st-${var.env}"
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_inbound_container
  type                   = "Block"

  depends_on = [module.sa]
}


resource "azurerm_storage_blob" "b2c_login_html" {
  name                   = "login.html"
  content_type           = "text/html"
  content_md5            = filemd5("./b2c/login.html")
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
  source                 = "./b2c/login.html"

  depends_on = [module.sa]
}

resource "azurerm_storage_blob" "b2c_login_css" {
  name                   = "login.css"
  content_type           = "text/css"
  content_md5            = filemd5("./b2c/login.css")
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
  source                 = "./b2c/login.css"

  depends_on = [module.sa]
}

resource "azurerm_storage_blob" "b2c_copyright_png" {
  name                   = "copyright.png"
  content_type           = "image/x-png"
  content_md5            = filemd5("./b2c/copyright.png")
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
  source                 = "./b2c/copyright.png"

  depends_on = [module.sa]
}

resource "azurerm_storage_blob" "b2c_favicon" {
  name                   = "favicon.ico"
  content_type           = "image/x-icon"
  content_md5            = filemd5("./b2c/favicon.ico")
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
  source                 = "./b2c/favicon.ico"

  depends_on = [module.sa]
}

resource "azurerm_storage_blob" "b2c_logo_gov" {
  name                   = "logo_gov.png"
  content_type           = "image/x-png"
  content_md5            = filemd5("./b2c/logo_gov.png")
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
  source                 = "./b2c/logo_gov.png"

  depends_on = [module.sa]
}

resource "azurerm_storage_blob" "b2c_mfa_html" {
  name                   = "mfa.html"
  content_type           = "text/html"
  content_md5            = filemd5("./b2c/mfa.html")
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
  source                 = "./b2c/mfa.html"

  depends_on = [module.sa]
}

resource "azurerm_storage_blob" "b2c_mfa_css" {
  name                   = "mfa.css"
  content_type           = "text/css"
  content_md5            = filemd5("./b2c/mfa.css")
  storage_account_name   = module.sa.storageaccount_name
  storage_container_name = local.darts_container_name
  type                   = "Block"
  source                 = "./b2c/mfa.css"

  depends_on = [module.sa]
}

resource "azurerm_role_assignment" "storage_contributors" {
  for_each             = toset(var.storage_account_contributor_ids)
  scope                = module.sa.storageaccount_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = each.value
}
