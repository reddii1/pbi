resource "azurerm_storage_blob" "powerbi-gateway" {
  name                   = "powerbi-gateway_download_install.ps1"
  storage_account_name   = azurerm_storage_account.shir.name
  storage_container_name = azurerm_storage_container.shir.name
  type                   = "Block"
  access_tier            = "Cool"
  source                 = "../scripts/powerbi-gateway_download_install.ps1"
}

resource "azurerm_network_interface" "powerbi-gateway" {
  name                = "nic-powerbi-gateway-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  ip_configuration {
    name                          = "ssms"
    subnet_id                     = azurerm_subnet.fe02[0].id 
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(var.tags, local.tags)
}

resource "azurerm_virtual_machine" "powerbi-gateway" {
  // The prefix "uksucc" is important for internal naming policies
  name                = "uksuccpowerbi-gateway"
  resource_group_name = azurerm_resource_group.powerbi-integration.name
  location            = var.location
  
  network_interface_ids = [azurerm_network_interface.powerbi-gateway.id,]

  // The size of the VM will probably need to be changed in time
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  // This picks up the image from the GoldImagesDevGallery/GoldImagesGallery depending on the environment
  storage_image_reference {
    id = data.azurerm_shared_image_version.win2022_latestGoldImage.id
  }
  storage_os_disk {
    name              = "osDiskpowerbi-gateway"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    // This MUST be randomised and stored in kv eventually
    admin_password = random_password.powerbi-gateway.result
  }

  os_profile_windows_config {
    provision_vm_agent = true
    enable_automatic_upgrades = false

  }
  identity {
    type = "SystemAssigned"
  }
 tags = merge(var.tags, local.tags, {
    "Persistence" = "Ignore"
  })
}

resource "random_password" "powerbi-gateway" {
  length           = 32
  special          = false
}

resource "azurerm_key_vault_secret" "powerbi-gateway" {
  name         = "powerbi-gateway-password"
  value        = random_password.powerbi-gateway.result
  key_vault_id = azurerm_key_vault.app.id
}

resource "azurerm_virtual_machine_extension" "powerbi-gateway" {
  name                       = "powerbi-gateway-installation"
  virtual_machine_id         = azurerm_virtual_machine.powerbi-gateway.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
 protected_settings = <<PROTECTED_SETTINGS
      {
          "fileUris": ["${format("https://%s.blob.core.windows.net/%s/%s", azurerm_storage_account.shir.name, azurerm_storage_container.shir.name, azurerm_storage_blob.powerbi-gateway.name)}"],
          "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ${azurerm_storage_blob.powerbi-gateway.name}",
          "storageAccountName": "${azurerm_storage_account.shir.name}",
          "storageAccountKey": "${azurerm_storage_account.shir.primary_access_key}"
      }
  PROTECTED_SETTINGS
  tags     = merge(var.tags, local.tags)

}
