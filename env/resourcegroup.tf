resource "azurerm_resource_group" "rg" {
  name     = "${var.namespace}-rg"
  location = "${var.location}"
}