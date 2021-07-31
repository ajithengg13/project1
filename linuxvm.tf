#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*
# Create a Linux VM 
#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*

#
# - Provider Block
#

provider "azurerm" {
    features {}
}

#
# - Create a Resource Group
#

resource "azurerm_resource_group" "rg" {
    name                  =   "${var.prefix}-rg"
    location              =   var.location
    tags                  =   var.tags
}

#
# - Create a Virtual Network
#

resource "azurerm_virtual_network" "vnet" {
    name                  =   "${var.prefix}-vnet"
    resource_group_name   =   azurerm_resource_group.rg.name
    location              =   azurerm_resource_group.rg.location
    address_space         =   [var.vnet_address_range]
    tags                  =   var.tags
}

#
# - Create a Subnet inside the virtual network
#

resource "azurerm_subnet" "web" {
    name                  =   "${var.prefix}-web-subnet"
    resource_group_name   =   azurerm_resource_group.rg.name
    virtual_network_name  =   azurerm_virtual_network.vnet.name
    address_prefixes      =   [var.subnet_address_range]
}

#
# - Create a Network Security Group
#

resource "azurerm_network_security_group" "nsg" {
    name                        =       "${var.prefix}-web-nsg"
    resource_group_name         =       azurerm_resource_group.rg.name
    location                    =       azurerm_resource_group.rg.location
    tags                        =       var.tags

    security_rule {
    name                        =       "Allow_SSH"
    priority                    =       1000
    direction                   =       "Inbound"
    access                      =       "Allow"
    protocol                    =       "tcp"
    source_port_range           =       "*"
    destination_port_range      =       22
    source_address_prefix       =       "*" 
    destination_address_prefix  =       "*"
    
    }
}


#
# - Subnet-NSG Association
#

resource "azurerm_subnet_network_security_group_association" "subnet-nsg" {
    subnet_id                    =       azurerm_subnet.web.id
    network_security_group_id    =       azurerm_network_security_group.nsg.id
}


#
# - Public IP (To Login to Linux VM)
#

resource "azurerm_public_ip" "pip" {
    count                           =     2
    name                            =     "linuxvm-public-ip${count.index}"
    resource_group_name             =     azurerm_resource_group.rg.name
    location                        =     azurerm_resource_group.rg.location
    allocation_method               =     var.allocation_method[0]
    tags                            =     var.tags
}

#
# - Create a Network Interface Card for Virtual Machine
#

resource "azurerm_network_interface" "nic" {
    count                             = 2
    name                              =   "Jenkins${count.index}"
    resource_group_name               =   azurerm_resource_group.rg.name
    location                          =   azurerm_resource_group.rg.location
    tags                              =   var.tags
    ip_configuration                  {
        name                          =  "${var.prefix}-nic-ipconfig"
        subnet_id                     =   azurerm_subnet.web.id
        public_ip_address_id          =   element(azurerm_public_ip.pip.*.id,count.index)
        private_ip_address_allocation =   var.allocation_method[1]
    }
}

#
# - Create a Linux Virtual Machine
# 


resource "azurerm_linux_virtual_machine" "vm1" {
    name                              =   "Jenkinsmaster"
    resource_group_name               =   azurerm_resource_group.rg.name
    location                          =   azurerm_resource_group.rg.location
    network_interface_ids             =   [azurerm_network_interface.nic.0.id]

    size                              =   var.virtual_machine_size
    computer_name                     =   "Jenkinsmaster"
    admin_username                    =   var.admin_username
    admin_password                    =   var.admin_password
    disable_password_authentication   =   false

    os_disk  {
        name                          =   "myosdisk0"
        caching                       =   var.os_disk_caching
        storage_account_type          =   var.os_disk_storage_account_type
        disk_size_gb                  =   var.os_disk_size_gb
    }
    source_image_reference {
        publisher                     =   var.publisher
        offer                         =   var.offer
        sku                           =   var.sku
        version                       =   var.vm_image_version
    }

    connection {
     type = "ssh"
     host = "${azurerm_public_ip.pip.0.ip_address}"
     user = "vmadmin"
     password = "Ajithkumar@1314"
    }

    provisioner "file" {
     source      = "master.sh"
     destination = "/home/vmadmin/master.sh"
    }

    provisioner "remote-exec" {
     inline = [
      "sudo apt-get update -y" ,
      "sudo apt-get install dos2unix" ,
      "dos2unix master.sh" ,
      "chmod +x /home/vmadmin/master.sh",
      "/home/vmadmin/master.sh ",
     ]
    }
}

resource "azurerm_linux_virtual_machine" "vm2" {
    name                              =   "Jenkinsbuild"
    resource_group_name               =   azurerm_resource_group.rg.name
    location                          =   azurerm_resource_group.rg.location
    network_interface_ids             =   [azurerm_network_interface.nic.1.id]

    size                              =   var.virtual_machine_size
    computer_name                     =   "Jenkinsbuild"
    admin_username                    =   var.admin_username
    admin_password                    =   var.admin_password
    disable_password_authentication   =   false

    os_disk  {
        name                          =   "myosdisk1"
        caching                       =   var.os_disk_caching
        storage_account_type          =   var.os_disk_storage_account_type
        disk_size_gb                  =   var.os_disk_size_gb
    }
    source_image_reference {
        publisher                     =   var.publisher
        offer                         =   var.offer
        sku                           =   var.sku
        version                       =   var.vm_image_version
    }

    connection {
    type = "ssh"
    host = "${azurerm_public_ip.pip.1.ip_address}"
    user = "vmadmin"
    password = "Ajithkumar@1314"
    }

 
  
   provisioner "file" {
     source      = "slave.sh"
     destination = "/home/vmadmin/slave.sh"
    }

    provisioner "remote-exec" {
     inline = [
      "sudo apt-get update -y" ,
      "sudo apt-get install dos2unix",
      "dos2unix slave.sh",
      "chmod +x /home/vmadmin/slave.sh",
      "/home/vmadmin/slave.sh ",
     ]
    }
      
   
}
   

    
  