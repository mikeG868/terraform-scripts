locals { 
nsgrules = {
 
    http = {
      name                       = "http"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }

    ssh = {
    name                       = "SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    # rdp = {
    #   name                       = "rdp"
    #   priority                   = 100
    #   direction                  = "Inbound"
    #   access                     = "Allow"
    #   protocol                   = "Tcp"
    #   source_port_range          = "*"
    #   destination_port_range    = "3389"
    #   source_address_prefix      = "VirtualNetwork"
    #   destination_address_prefix = "*"
    # }
 
    # sql = {
    #   name                       = "sql"
    #   priority                   = 101
    #   direction                  = "Inbound"
    #   access                     = "Allow"
    #   protocol                   = "Tcp"
    #   source_port_range          = "*"
    #   destination_port_range     = "1433"
    #   source_address_prefix      = "SqlManagement"
    #   destination_address_prefix = "192.168.2.0/24"
    # }
  }
 
}