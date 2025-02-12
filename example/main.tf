# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "sonarqube"
  location = "value"
}

# Virtual Networks
resource "azurerm_virtual_network" "vnet" {
  name                = "sonarqubevnet"
  address_space       = local.vnet_address_space
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

# Subnets
resource "azurerm_subnet" "subnet_privateendpoints" {
  name                 = "sonarqubesubnetprivateendpoints"
  address_prefixes     = local.subnet_address_range_private_endpoints
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  service_endpoints = [
    "Microsoft.Storage",
  ]
}

resource "azurerm_subnet" "subnet_appgw" {
  name                 = "sonarqubesubnetappgw"
  address_prefixes     = local.subnet_address_range_appgw
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet_pgsql" {
  name                 = "sonarqubesubnetpgsql"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = local.subnet_address_range_pgsql
  delegation {
    name = "Microsoft.DBforPostgreSQL/flexibleServers"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "nsg_web" {
  name                = "sonarqubensgweb"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow inbound HTTP(S) traffic
  security_rule {
    name                       = "AllowWebInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "80"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "nsg_appgw" {
  name                = "sonarqubensgappgw"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow inbound HTTP traffic
  security_rule {
    name                       = "AllowWebInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow AppGw inbound traffic
  security_rule {
    name                       = "AllowAppGwInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_network_security_group" "nsg_db" {
  name                = "sonarqubensgdb"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow PostgreSQL inbound traffic
  security_rule {
    name                       = "AllowPostgreSQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "nsg_privateendpoints" {
  subnet_id                 = azurerm_subnet.subnet_privateendpoints.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_containers" {
  subnet_id                 = azurerm_subnet.subnet_containers.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_appgw" {
  subnet_id                 = azurerm_subnet.subnet_appgw.id
  network_security_group_id = azurerm_network_security_group.nsg_appgw.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_pgsql" {
  subnet_id                 = azurerm_subnet.subnet_pgsql.id
  network_security_group_id = azurerm_network_security_group.nsg_db.id
}

provider "azurerm" {
  features {}
  subscription_id = "XXX"
}

module "sonarqube" {
  source                      = "../"
  sonar_image_tag             = "10.7.0-community"
  location                    = local.location
  resource_group_name         = azurerm_resource_group.rg.name
  vnet_id                     = azurerm_virtual_network.vnet.id
  subnet_private_endpoints_id = azurerm_subnet.subnet_privateendpoints.id
  subnet_pgsql_id             = azurerm_subnet.subnet_pgsql.id
  subnet_appgw_id             = azurerm_subnet.subnet_appgw.id
  kv_admins                   = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]
}
