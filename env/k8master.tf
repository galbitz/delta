
resource "azurerm_public_ip" "master-ip" {
  name                         = "${var.namespace}-master-ip"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "Dynamic"
  idle_timeout_in_minutes      = 30
}

resource "azurerm_network_interface" "master-nic" {
  name                = "${var.namespace}-master-nic"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "master-ip-config"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.0.0.5"
    public_ip_address_id          = "${azurerm_public_ip.master-ip.id}"
  }
}

resource "azurerm_virtual_machine" "master-vm" {
  name                         = "${var.namespace}-master-vm"
  location                     = "${azurerm_resource_group.rg.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  network_interface_ids        = ["${azurerm_network_interface.master-nic.id}"]
  primary_network_interface_id = "${azurerm_network_interface.master-nic.id}"
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
    name          = "${var.namespace}-master-disk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "k8master"
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
  virtual_machine_name = "${azurerm_virtual_machine.master-vm.name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = ["azurerm_virtual_machine.master-vm", "azurerm_storage_blob.master"]

  settings = <<SETTINGS
    {
        "fileUris": [
          "${azurerm_storage_account.storage.primary_blob_endpoint}${azurerm_storage_container.artifacts.name}/master.sh"
        ],
        "commandToExecute": "sh master.sh"

    }
SETTINGS
}

data "azurerm_public_ip" "master-public-ip" {
  name                = "${azurerm_public_ip.master-ip.name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  depends_on          = ["azurerm_virtual_machine.master-vm"]
}

output "master-vm-ip_address" {
  value = "${data.azurerm_public_ip.master-public-ip.ip_address}"
}