# Commons
variable "name" {
  description = "Name to be used on all the resources as an identifier."
  type        = string
  default     = "sonarqube"
}

variable "tags" {
  description = "A map of tags to add to all resources for better resource organization and cost management."
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Azure region where all resources will be deployed."
  type        = string
  default     = "northeurope"
}

variable "resource_group_name" {
  description = "The name of the Azure resource group where resources will be deployed."
  type        = string
}

variable "admins_allowed_ips" {
  description = "Mapping of admin users to their allowed public IP addresses for security restrictions."
  type        = map(string)
  default     = {}
}

# Networking
variable "vnet_id" {
  description = "ID of the VNet"
  type        = string
}

variable "vnet_address_space" {
  description = "CIDR block(s) defining the address space for the virtual network."
  type        = list(string)
}

variable "subnet_address_range_private_endpoints" {
  description = "CIDR block(s) defining the address range for private endpoints subnet."
  type        = list(string)
}

variable "subnet_address_range_containers" {
  description = "CIDR block(s) defining the address range for the containerized applications subnet."
  type        = list(string)
}

variable "subnet_address_range_appgw" {
  description = "CIDR block(s) defining the address range for the Application Gateway subnet."
  type        = list(string)
}

variable "subnet_address_range_pgsql" {
  description = "CIDR block(s) defining the address range for the PostgreSQL database subnet."
  type        = list(string)
}

# Key Vault
variable "keyvault" {
  description = "Configuration for Azure Key Vault, including SKU, soft delete period, purge protection, and secret expiration."
  type = object({
    sku                    = string
    soft_delete_period     = number
    purge_protection       = bool
    secret_expiration_days = number
  })
  default = {
    sku                    = "standard"
    soft_delete_period     = 90
    purge_protection       = true
    secret_expiration_days = 3650 // 10 years
  }
}

variable "kv_admins" {
  description = "A list of user IDs with admin privileges over the Azure Key Vault."
  type        = list(string)
}

# Storage Accounts
variable "storage_account" {
  description = "Configuration for the Azure Storage Account, including security settings, replication, and soft delete periods."
  type = object({
    account_kind                 = string
    account_tier                 = string
    account_replication_type     = string
    https_traffic_only_enabled   = string
    min_tls_version              = string
    is_hns_enabled               = string
    nfsv3_enabled                = string
    sftp_enabled                 = string
    blob_soft_delete_period      = number
    container_soft_delete_period = number
    key_rotation_reminder        = number
  })
  default = {
    account_kind                 = "StorageV2"
    account_tier                 = "Standard"
    account_replication_type     = "LRS"
    https_traffic_only_enabled   = "true"
    min_tls_version              = "TLS1_2"
    is_hns_enabled               = "false"
    nfsv3_enabled                = "false"
    sftp_enabled                 = "false"
    blob_soft_delete_period      = 7
    container_soft_delete_period = 7
    key_rotation_reminder        = 90
  }
}

# SonarQube
variable "sonar_db_server" {
  description = "The name of the SonarQube database server instance."
  type        = string
  default     = "sonardbserver"
}

variable "sonar_db_instance_class" {
  description = "The database instance class used for SonarQube (e.g., db.t4g.micro for AWS RDS)."
  type        = string
  default     = "db.t4g.micro"
}

variable "sonar_db_storage_type" {
  description = "The storage type used for the SonarQube database server (e.g., gp2 for AWS EBS-backed storage)."
  type        = string
  default     = "gp2"
}

variable "sonar_db_name" {
  description = "The name of the SonarQube database to be created."
  type        = string
  default     = "sonar"
}

variable "sonar_db_user" {
  description = "The username for authenticating to the SonarQube database."
  type        = string
  default     = "sonar"
}

variable "sonar_port" {
  description = "The port on which the SonarQube service will be exposed."
  type        = number
  default     = 9000
}

variable "sonar_container_name" {
  description = "The name of the SonarQube container instance used in the deployment."
  type        = string
  default     = "sonarqube"
}

variable "sonar_image_tag" {
  description = "The specific tag of the SonarQube Docker image to deploy (e.g., `9.9.2-community`)."
  type        = string
}
