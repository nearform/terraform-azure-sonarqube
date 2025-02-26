locals {
  name                                   = "sonarqubetest"
  location                               = "northeurope"
  vnet_address_space                     = ["172.17.0.0/21"]
  subnet_address_range_private_endpoints = ["172.17.1.0/24"]
  subnet_address_range_pgsql             = ["172.17.2.0/24"]
  subnet_address_range_appgw             = ["172.17.3.0/24"]
  subnet_address_range_aci               = ["172.17.4.0/24"]
  sonar_image_tag                        = "10.7.0-community"
  sonar_port                             = "9000"
  common_tags = {
    Project     = "sonarqube"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
