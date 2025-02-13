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
variable "subnet_private_endpoints_id" {
  description = "The ID of the subnet used for private endpoints."
  type        = string
}

variable "subnet_pgsql_id" {
  description = "The ID of the subnet used for the PostgreSQL database."
  type        = string
}

variable "subnet_appgw_id" {
  description = "The ID of the subnet used for the Application Gateway."
  type        = string
}

variable "subnet_aci_id" {
  description = "The ID of the subnet used for the ACI."
  type        = string
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
  default     = []
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
  description = "The database instance class used for SonarQube."
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "sonar_db_storage_type" {
  description = "The storage type used for the SonarQube database server."
  type        = string
  default     = "P10"
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
  description = "The specific tag of the SonarQube Docker image to deploy."
  type        = string
  default     = "community"
}
