variable "master-ips" {
  default = {
    "0" = "10.0.0.5"
    "1" = "10.0.0.6"
  }
}

variable "master-count" {
  default = 1
}

resource "azurerm_availability_set" "master-avset" {
  name                         = "${var.namespace}-master-avset"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  managed                      = true
}

resource "azurerm_network_interface" "master-nic" {
  name                = "${var.namespace}-master-nic-${count.index}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  count               = "${var.master-count}"

  ip_configuration {
    name                          = "master-ip-config${count.index}"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${lookup(var.master-ips,count.index)}"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "master-addresspool" {
  network_interface_id    = "${element(azurerm_network_interface.master-nic.*.id,count.index)}"
  ip_configuration_name   = "master-ip-config${count.index}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  count                   = "${var.master-count}"
}

resource "azurerm_network_interface_nat_rule_association" "master-nat" {
  network_interface_id  =  "${element(azurerm_network_interface.master-nic.*.id,count.index)}"
  ip_configuration_name = "master-ip-config${count.index}"
  nat_rule_id           = "${element(azurerm_lb_nat_rule.ssh_rule_master.*.id,count.index)}"
  count                 = "${var.master-count}"
}

resource "azurerm_virtual_machine" "master-vm" {
  name                         = "${var.namespace}-master-vm-${count.index}"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  availability_set_id          = "${azurerm_availability_set.master-avset.id}"
  network_interface_ids        = ["${element(azurerm_network_interface.master-nic.*.id,count.index)}"]
  vm_size                      = "${var.vmsize}"
  count                        = "${var.master-count}"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.namespace}-master-disk-${count.index}"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "k8master${count.index}"
    admin_username = "${var.adminusername}"
    admin_password = "${var.adminpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "master-vm-extension" {
  name                 = "linuxext"
  location             = "${azurerm_resource_group.rg.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.master-vm.*.name,0)}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = ["azurerm_virtual_machine.master-vm", "azurerm_storage_blob.master"]

  settings = <<SETTINGS
    {
        "fileUris": [
          "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.artifacts.name}/master.sh"
        ],
        "commandToExecute": "bash master.sh"

    }
SETTINGS
}
