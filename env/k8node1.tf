variable "node-ips" {
  default = {
    "0" = "10.0.0.10"
    "1" = "10.0.0.11"
    "2" = "10.0.0.12"
  }
}

variable "node-count" {
  default = 2
}

resource "azurerm_availability_set" "node-avset" {
  name                         = "${var.namespace}-node-avset"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  managed                      = true
}

resource "azurerm_network_interface" "node-nic" {
  name                = "${var.namespace}-node-nic-${count.index}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  count               = "${var.node-count}"

  ip_configuration {
    name                          = "node-ip-config${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${lookup(var.node-ips,count.index)}"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "node-addresspool" {
  network_interface_id    = "${element(azurerm_network_interface.node-nic.*.id, count.index)}"
  ip_configuration_name   = "node-ip-config${count.index}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool2.id}"
  count                   = "${var.node-count}"
}

resource "azurerm_network_interface_nat_rule_association" "node-nat" {
  network_interface_id  = "${element(azurerm_network_interface.node-nic.*.id,count.index)}"
  ip_configuration_name = "node-ip-config${count.index}"
  nat_rule_id           = "${element(azurerm_lb_nat_rule.ssh_rule_node.*.id,count.index)}"
  count                 = "${var.node-count}"
}

resource "azurerm_virtual_machine" "node-vm" {
  name                         = "${var.namespace}-node-vm-${count.index}"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  availability_set_id          = "${azurerm_availability_set.node-avset.id}"
  network_interface_ids        = ["${element(azurerm_network_interface.node-nic.*.id,count.index)}"]
  vm_size                      = "${var.vmsize}"
  count                        = "${var.node-count}"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.namespace}-node-disk-${count.index}"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "k8node${count.index}"
    admin_username = "${var.adminusername}"
    admin_password = "${var.adminpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "node-vm-extension" {
  name                 = "linuxext"
  location             = "${azurerm_resource_group.rg.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.node-vm.*.name,count.index)}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = ["azurerm_virtual_machine.node-vm", "azurerm_storage_blob.node", "azurerm_virtual_machine_extension.master-vm-extension"]
  count                = "${var.node-count}"

  settings = <<SETTINGS
    {
        "fileUris": [
          "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.artifacts.name}/node.sh"
        ],
        "commandToExecute": "bash node.sh"

    }
SETTINGS
}
