resource "azurerm_public_ip" "lb-ip" {
  name                         = "${var.namespace}-lb-ip"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30
  #domain_name_label            = 
}

resource "azurerm_lb" "lb" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  name                = "${var.namespace}-lb"
  location            = "${azurerm_resource_group.rg.location}"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = "${azurerm_public_ip.lb-ip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "BackendPool1"
}

resource "azurerm_lb_nat_rule" "ssh_rule_master" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  name                           = "ssh-master-${count.index}"
  protocol                       = "tcp"
  frontend_port                  = "5000${count.index}"
  backend_port                   = 22
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  count                          = "${var.master-count}"
}

# resource "azurerm_lb_probe" "lb_probe" {
#   resource_group_name = "${azurerm_resource_group.rg.name}"
#   loadbalancer_id     = "${azurerm_lb.lb.id}"
#   name                = "tcpProbe"
#   protocol            = "tcp"
#   port                = 80
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

data "azurerm_public_ip" "lb-public-ip" {
  name                = "${azurerm_public_ip.lb-ip.name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  depends_on          = ["azurerm_virtual_machine.master-vm"]
}

output "lb-ip_address" {
  value = "${data.azurerm_public_ip.lb-public-ip.ip_address}"
}