data "azurerm_subnet" "private_endpoints_dets_sa" {
  resource_group_name  = local.private_endpoint_rg_name
  virtual_network_name = local.private_endpoint_vnet_name
  name                 = "private-endpoints"
}

data "azurerm_subnet" "jenkins_agents" {
  provider             = azurerm.jenkins_agents
  resource_group_name  = local.jenkins_agents.rg_name
  virtual_network_name = local.jenkins_agents.vnet_name
  name                 = local.jenkins_agents.subnet_name
}