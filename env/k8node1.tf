
resource "azurerm_public_ip" "node1-ip" {
  name                         = "${var.namespace}-node1-ip"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30
}

resource "azurerm_network_interface" "node1-nic" {
  name                = "${var.namespace}-node1-nic"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "node1-ip-config"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.0.6"
    public_ip_address_id          = "${azurerm_public_ip.node1-ip.id}"
  }
}

resource "azurerm_virtual_machine" "node1-vm" {
  name                         = "${var.namespace}-node1-vm"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  network_interface_ids        = ["${azurerm_network_interface.node1-nic.id}"]
  primary_network_interface_id = "${azurerm_network_interface.node1-nic.id}"
  vm_size                      = "${var.vmsize}"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "${var.namespace}-node1-disk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "k8node1"
    admin_username = "${var.adminusername}"
    admin_password = "${var.adminpassword}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# resource "azurerm_virtual_machine_extension" "control-vm-extension" {
#   name                 = "linuxext"
#   location             = "${azurerm_resource_group.rg.location}"
#   resource_group_name  = "${azurerm_resource_group.rg.name}"
#   virtual_machine_name = "${azurerm_virtual_machine.control-vm.name}"
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"
#   depends_on           = ["azurerm_virtual_machine.control-vm", "azurerm_storage_blob.provision", "azurerm_storage_blob.assign_drives", "azurerm_storage_blob.ConfigureRemotingForAnsible", "azurerm_storage_blob.ansible_install_centos", "azurerm_storage_blob.webdeploypriv", "azurerm_storage_blob.provisionsh"]

#   settings = <<SETTINGS
#     {
#         "fileUris": [
#           "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.artifacts.name}/control/ansible_install_centos.sh",
#           "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.artifacts.name}/control/provision.sh",
#           "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.artifacts.name}/control/webdeploy.priv",
#           "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.artifacts.name}/control/webdeploy.pub"
#         ],
#         "commandToExecute": "sh provision.sh"

#     }
# SETTINGS
# }

data "azurerm_public_ip" "node1-public-ip" {
  name                = "${azurerm_public_ip.node1-ip.name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  depends_on          = ["azurerm_virtual_machine.node1-vm"]
}

output "node1-vm-ip_address" {
  value = "${data.azurerm_public_ip.node1-public-ip.ip_address}"
}