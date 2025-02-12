# terraform-azure-sonarqube

A Terraform module for deploying SonarQube on Azure as a containerized service. This module automates the provisioning and management of SonarQube infrastructure using Azure services, ensuring a **secure, scalable, and private deployment**.

## Features

This Terraform module deploys a **SonarQube container** in **Azure Container Instances (ACI)** with **private networking**. It includes the following components:

- **Azure Container Instances (ACI)** – Runs the SonarQube container within a secure environment.
- **Azure Database for PostgreSQL Flexible Server** – Provides a managed PostgreSQL database for SonarQube.
- **Azure Key Vault** – Stores sensitive information such as database credentials securely.
- **Azure Application Gateway (AppGW)** – Acts as the entry point for external access while keeping all internal resources private.
- **Azure Storage Account** – Provides persistent storage for SonarQube data.
- **Private Deployment** – The entire infrastructure is **deployed in a private network**, with external access routed exclusively through the **Application Gateway**.

This setup ensures a **cost-effective, reliable, and secure** SonarQube deployment on Azure.

## Requirements

- Terraform v1.9+
- Azure CLI
- An Azure account with necessary permissions
- **Pre-existing networking infrastructure:** This module requires that the VNet, subnets, and networking resources are deployed beforehand.

## Inputs

| Name                          | Description                                           | Type           | Default                | Required |
| ----------------------------- | ----------------------------------------------------- | -------------- | ---------------------- | -------- |
| `name`                        | Name to be used on all resources as an identifier     | `string`       | `"sonarqube"`          | no       |
| `tags`                        | A map of tags to add to all resources                 | `map(string)`  | `{}`                   | no       |
| `location`                    | Azure region where resources will be deployed         | `string`       | `"northeurope"`        | no       |
| `resource_group_name`         | The name of the Azure resource group                  | `string`       | N/A                    | yes      |
| `admins_allowed_ips`          | Mapping of admin users to their allowed public IPs    | `map(string)`  | `{}`                   | no       |
| `vnet_id`                     | ID of the Virtual Network                             | `string`       | N/A                    | yes      |
| `subnet_private_endpoints_id` | The ID of the subnet used for private endpoints       | `string`       | N/A                    | yes      |
| `subnet_pgsql_id`             | The ID of the subnet used for the PostgreSQL database | `string`       | N/A                    | yes      |
| `subnet_appgw_id`             | The ID of the subnet used for the Application Gateway | `string`       | N/A                    | yes      |
| `keyvault`                    | Configuration for Azure Key Vault                     | `object`       | See below              | no       |
| `kv_admins`                   | List of user IDs with admin privileges over Key Vault | `list(string)` | N/A                    | yes      |
| `storage_account`             | Configuration for the Azure Storage Account           | `object`       | See below              | no       |
| `sonar_db_server`             | The name of the SonarQube database server             | `string`       | `"sonardbserver"`      | no       |
| `sonar_db_instance_class`     | The instance class for the SonarQube database         | `string`       | `"GP_Standard_D2s_v3"` | no       |
| `sonar_db_storage_type`       | The storage type for the SonarQube database           | `string`       | `"P10"`                | no       |
| `sonar_db_name`               | The name of the SonarQube database                    | `string`       | `"sonar"`              | no       |
| `sonar_db_user`               | The username for the SonarQube database               | `string`       | `"sonar"`              | no       |
| `sonar_port`                  | The port on which SonarQube will run                  | `number`       | `9000`                 | no       |
| `sonar_container_name`        | The name of the SonarQube container                   | `string`       | `"sonarqube"`          | no       |
| `sonar_image_tag`             | The Docker Hub tag of the SonarQube image to deploy   | `string`       | N/A                    | yes      |

### Default Configuration for Key Vault

```hcl
keyvault = {
  sku                    = "standard"
  soft_delete_period     = 90
  purge_protection       = true
  secret_expiration_days = 3650
}
```

### Default Configuration for Storage Account

```hcl
storage_account = {
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
```

## Outputs

| Name         | Description                                                                 |
| ------------ | --------------------------------------------------------------------------- |
| `appgw_fqdn` | The fully qualified domain name (FQDN) of the Application Gateway public IP |

## Examples

### **Basic Usage**

The following example deploys SonarQube in Azure using the Terraform module.

```hcl
module "sonarqube" {
  source = "github.com/nearform/terraform-azure-sonarqube"

  # General Configuration
  name  = "sonarqube"
  tags  = {
    Environment = "dev"
    Project     = "sonarqube"
  }

  # Networking
  resource_group_name         = "sonarqube"
  location                    = "northeurope"
  vnet_id                     = "vnet-xxxxxxxx"
  subnet_private_endpoints_id = "subnet-xxxxxxxx"
  subnet_pgsql_id             = "subnet-xxxxxxxx"
  subnet_appgw_id             = "subnet-xxxxxxxx"

  # Key Vault
  kv_admins = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]

  # SonarQube Configuration
  sonar_db_server          = "sonardbserver"
  sonar_db_instance_class  = "Standard_D2s_v3"
  sonar_db_storage_type    = "Premium_LRS"
  sonar_db_name            = "sonar"
  sonar_db_user            = "sonar"
  sonar_port               = 9000
  sonar_container_name     = "sonarqube"
  sonar_image_tag          = "community"
}
```

### Customizing SonarQube Version

You can specify a different version of the SonarQube Docker image by setting the `sonar_image_tag` variable:

```hcl
sonar_image_tag = "9.9.1-community"
```

### Using a Different Database Instance

If you need a larger database instance for better performance:

```hcl
sonar_db_instance_class = "Standard_D4s_v3"
```

## Contributing

We welcome contributions to improve this Terraform module! Here’s how you can contribute:

1. **Fork the repository** - Create a personal fork of this repository to make your changes.
2. **Create a new branch** - For each contribution, create a new branch from `main`.
3. **Make your changes** - Implement your changes, and ensure that the code adheres to the existing style.
4. **Write tests** - If applicable, write tests to cover your changes.
5. **Commit and push** - Commit your changes with descriptive messages and push them to your fork.
6. **Create a pull request** - Open a pull request from your fork’s branch to the main repository’s `main` branch.
7. **Be respectful** - Be mindful and respectful in discussions.

For larger changes or new features, please open an issue first to discuss the approach before starting work on it.

Thanks for helping improve this project!
