###########################
### Variables for setup ###
###########################

// must be randomised and put in kv eventually
variable "sql_admin_username" {
    type = string
default       = "notATypicalSQLIdentifier"
}


resource "random_password" "adf-sql_admin_password" {
  length           = 32
  special          = false
}

resource "azurerm_key_vault_secret" "adf-sql_admin_password" {
  name         = "curated-password"
  value        = random_password.adf-sql_admin_password.result
  key_vault_id = azurerm_key_vault.app.id
}
//this has to be lowercase for the mssql naming policies
resource "random_string" "randomlower" {
    length = 8
    special = false
    upper = false
}
 
# Define Azure SQL Server

######################
### Azure SQL PaaS ###
######################
resource "azurerm_mssql_server" "curated" {
  name                         = "curated-mi"
  resource_group_name          = azurerm_resource_group.powerbi-integration.name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.adf-sql_admin_password.result
  //has to be blocked for dwp internal policies
  public_network_access_enabled = false
  tags     = merge(var.tags, local.tags)
}

resource "azurerm_mssql_database" "curated" {
  name                = "curated-mi"
  server_id      = azurerm_mssql_server.curated.id
  tags     = merge(var.tags, local.tags)

#   # prevent the possibility of accidental data loss
#   lifecycle {
#     prevent_destroy = true
#   }

}
