#####################################
### endpoint private connectivity ##
####################################

# Private Endpoint for Data Factory to be accessible from be02 as this is the data subnet
resource "azurerm_private_endpoint" "datafactory" {
  name                = "datafactory-private-endpoint-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  subnet_id           = azurerm_subnet.be02[0].id //in a subnet accessible to mysqlfs
 
  private_service_connection {
    name                           = "datafactory-connection"
    private_connection_resource_id = azurerm_data_factory.adf.id
    subresource_names              = ["dataFactory"]
    is_manual_connection           = false
  }
    private_dns_zone_group {
    name                 = "datafactory-${terraform.workspace}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.datafactory.id]
  }
  tags     = merge(var.tags, local.tags)
}

data "azurerm_private_dns_zone" "datafactory" {
  name                 = "privatelink.datafactory.azure.net" // no prefix can be added to this link.
  resource_group_name  = local.uks_shared_services_dns_resourcegroup[terraform.workspace]
  provider             = azurerm.shared_services_uks
  tags     = merge(var.tags, local.tags)
}

############################
### curated privatelink ###
###########################
// this private endpoint is based on the service connection already in existence in rg_network. 
// this brings a private connection point again in fe02 to be accessible by the SHIR there (again where tableau was)
resource "azurerm_private_endpoint" "curated" {

  name                = "curated-private-endpoint-mi"
  location            = var.location
  resource_group_name = azurerm_subnet.be02[0].resource_group_name
  subnet_id           = azurerm_subnet.be02[0].id
    private_service_connection {
    name                           = "azure-sql-connection"
    subresource_names = ["sqlServer"]
    private_connection_resource_id = azurerm_mssql_server.curated.id
    is_manual_connection           = false
  }
    private_dns_zone_group {
    name                 = "curated-${terraform.workspace}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.curated.id]

  }
  tags     = merge(var.tags, local.tags)
}

data "azurerm_private_dns_zone" "curated" {
  name                 = "privatelink.database.windows.net"
  resource_group_name  = azurerm_subnet.be02[0].resource_group_name
  tags     = merge(var.tags, local.tags)
}
