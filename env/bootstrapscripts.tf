resource "azurerm_storage_account" "storage" {
  name                     = "${var.namespace}bootstrapstorage"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "artifacts" {
  name                  = "${var.namespace}-artifacts"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.storage.name}"
  container_access_type = "container"
}

resource "azurerm_storage_blob" "master" {
  name                   = "master.sh"
  resource_group_name    = "${azurerm_resource_group.rg.name}"
  storage_account_name   = "${azurerm_storage_account.storage.name}"
  storage_container_name = "${azurerm_storage_container.artifacts.name}"
  source                 = "..\\bootstrap\\master.sh"
  type                   = "block"
}

resource "azurerm_storage_blob" "node" {
  name                   = "node.sh"
  resource_group_name    = "${azurerm_resource_group.rg.name}"
  storage_account_name   = "${azurerm_storage_account.storage.name}"
  storage_container_name = "${azurerm_storage_container.artifacts.name}"
  source                 = "..\\bootstrap\\node.sh"
  type                   = "block"
}

