resource "azurerm_public_ip" "backend-lb-ip" {
  name                         = "${var.namespace}-backend-lb-ip"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30
  #domain_name_label            = 
}

resource "azurerm_lb" "backend-lb" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  name                = "${var.namespace}-backend-lb"
  location            = "${azurerm_resource_group.rg.location}"

  frontend_ip_configuration {
    name                 = "BackendLoadBalancerFrontEnd"
    public_ip_address_id = "${azurerm_public_ip.backend-lb-ip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool2" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.backend-lb.id}"
  name                = "BackendPool2"
}

resource "azurerm_lb_nat_rule" "ssh_rule_node" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.backend-lb.id}"
  name                           = "ssh-node-${count.index}"
  protocol                       = "tcp"
  frontend_port                  = "5000${count.index}"
  backend_port                   = 22
  frontend_ip_configuration_name = "BackendLoadBalancerFrontEnd"
  count                          = "${var.node-count}"
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.backend-lb.id}"
  name                           = "Inbound-http"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "BackendLoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool2.id}"
  idle_timeout_in_minutes        = 5
  #probe_id                       = "${azurerm_lb_probe.lb_probe.id}"
  #depends_on                     = ["azurerm_lb_probe.lb_probe"]
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

data "azurerm_public_ip" "lb-backend-public-ip" {
  name                = "${azurerm_public_ip.backend-lb-ip.name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  depends_on          = ["azurerm_virtual_machine.master-vm"]
}

output "backend-lb-ip_address" {
  value = "${data.azurerm_public_ip.lb-backend-public-ip.ip_address}"
}