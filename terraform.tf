variable "default_user" {
}

variable "default_password" {
}

variable "subscription_id" {
}

variable "client_id" {
}

variable "client_secret" {
}

variable "tenant_id" {
}

variable "vm_strage_account_name" {
}

variable "vsts_account_name" {
}

variable "vsts_personal_access_token" {
}

variable "vsts_agent_name" {
}

variable "vsts_agent_pool_name" {
}


provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "test" {
  name     = "K8sVSTSAgentResource"
  location = "Japan East"
}

resource "azurerm_virtual_network" "test" {
  name                = "acctvn"
  address_space       = ["10.0.0.0/16"]
  location            = "Japan East"
  resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "acctsub"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "test" {
  name                         = "BuildSV8"
  location                     = "Japan East"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "sabuilds2"

  tags {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "test" {
  name                = "acctni"
  location            = "Japan East"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
  }
}

resource "azurerm_storage_account" "test" {
  name                = "${var.vm_strage_account_name}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  location            = "japaneast"
  account_type        = "Standard_LRS"

  tags {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "test" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  storage_account_name  = "${azurerm_storage_account.test.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "test" {
  name                  = "BuildVM03"
  location              = "Japan East"
  resource_group_name   = "${azurerm_resource_group.test.name}"
  network_interface_ids = ["${azurerm_network_interface.test.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.test.primary_blob_endpoint}${azurerm_storage_container.test.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "BuildVM03"
    admin_username = "${var.default_user}"
    admin_password = "${var.default_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
  

  provisioner "file" {
    source      = "provisioning.sh"
    destination = "/home/azureuser/provisioning.sh"

    connection {
      type     = "ssh"
      user     = "${var.default_user}"
      password = "${var.default_password}"
      host     = "${azurerm_public_ip.test.ip_address}"
    }
  }
    provisioner "file" {
    source      = ".bash_profile"
    destination = "/home/azureuser/.bash_profile"

    connection {
      type     = "ssh"
      user     = "${var.default_user}"
      password = "${var.default_password}"
      host     = "${azurerm_public_ip.test.ip_address}"
    }
  }

    provisioner "file" {
    source      = "vsts-agent-ubuntu.16.04-x64-2.110.0.tar.gz"
    destination = "/home/azureuser/vsts-agent-ubuntu.16.04-x64-2.110.0.tar.gz"

    connection {
      type     = "ssh"
      user     = "${var.default_user}"
      password = "${var.default_password}"
      host     = "${azurerm_public_ip.test.ip_address}"
    }
  }

      provisioner "file" {
    source      = "config"
    destination = "/home/azureuser/config"

    connection {
      type     = "ssh"
      user     = "${var.default_user}"
      password = "${var.default_password}"
      host     = "${azurerm_public_ip.test.ip_address}"
    }
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "${var.default_user}"
      password = "${var.default_password}"
      host     = "${azurerm_public_ip.test.ip_address}"
    }

    inline = [
      "sudo chmod +x /home/azureuser/provisioning.sh; /home/azureuser/provisioning.sh ${var.vsts_account_name} ${var.vsts_personal_access_token} ${var.vsts_agent_name} ${var.vsts_agent_pool_name} ${var.default_user} > /tmp/terraform.log",
    ]
  }
}
