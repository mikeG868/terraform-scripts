# Configure the Azure provider
terraform {
/*   backend "azurerm" {
    resource_group_name = "samu-rg"
    storage_account_name = "samu1storage1account"
    container_name = "terraform-state"
    key = "terraform.tfstate"
  } */
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }


  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

#Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "northeurope"
  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

#Storage
resource "azurerm_storage_account" "storage" {
  name                     = "mikestoracc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = "mikecontainer"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# resource "azurerm_storage_blob" "example" {
#   name                   = "my-awesome-content.zip"
#   storage_account_name   = azurerm_storage_account.example.name
#   storage_container_name = azurerm_storage_container.example.name
#   type                   = "Block"
#   source                 = "some-local-file.zip"
# }

resource "azurerm_storage_management_policy" "storagepolicy" {
  storage_account_id = azurerm_storage_account.storage.id

  rule {
    name    = "rule1"
    enabled = true
    filters {
      # prefix_match = ["container1/prefix1"]
      blob_types   = ["blockBlob"]
      # match_blob_index_tag {
      #   name      = "tag1"
      #   operation = "=="
      #   value     = "val1"
      # }
    }
    actions {
      base_blob {
        # tier_to_cool_after_days_since_modification_greater_than    = 10
        # tier_to_archive_after_days_since_modification_greater_than = 50
        delete_after_days_since_modification_greater_than          = 1
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 1
      }
    }
  }
}


#Virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-terraform"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-terraform"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "testpip"
  location            = azurerm_virtual_network.vnet.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "NSG-terraform"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "multirule-nsg" {
  for_each                    = local.nsgrules 
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-terraform"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "publicIP"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_subnet_network_security_group_association" "nsgtosubnet" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#Virtual machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "Ubuntu-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_D2_v2"
  disable_password_authentication = "false"
  admin_username        = "mike"
  admin_password        = var.vm_password

  network_interface_ids = [azurerm_network_interface.nic.id]

  # This is where we pass our cloud-init.
  # Encode and pass you script
  custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  
  # admin_ssh_key {
  #   username   = "mike"
  #   public_key = file("~/.ssh/id_rsa.pub")
  # }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

#Data template cloud init
data "template_file" "linux-vm-cloud-init" {
  template = file("./cloud_init.sh")
}

#Cloud init/custom data using extension

# resource "azurerm_virtual_machine_extension" "vmextension" {

#   virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
#   name                       = "vme"
#   publisher                  = "Microsoft.Azure.Extensions"
#   type                       = "CustomScript"
#   type_handler_version       = "2.0"
#   auto_upgrade_minor_version = true

#   settings = <<SETTINGS
#   {
#     "commandToExecute": "sudo apt-get update && apt-get install -y apache2 && echo 'hello world' > /var/www/html/index.html"
#   }
#   SETTINGS
# }


