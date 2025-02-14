# terraform-azure-sonarqube

A Terraform module for deploying SonarQube on Azure as a containerized service. This module automates the provisioning and management of SonarQube infrastructure using Azure services, ensuring a **secure, scalable, and private deployment**.

## Features

This Terraform module deploys a **SonarQube container** in **Azure Container Instances (ACI)** with **private networking**. It includes the following components:

- **Azure Container Instances (ACI)** – Runs the SonarQube container within a secure and scalable environment.
- **Azure Database for PostgreSQL Flexible Server** – Provides a managed PostgreSQL database for SonarQube.
- **Azure Key Vault** – Securely stores sensitive information such as database credentials.
- **Azure Application Gateway (AppGW)** – Acts as the entry point for external access while keeping all internal resources private.
- **Azure Storage Account** – Ensures persistent storage for SonarQube data, including logs, extensions, and cache.
- **Azure Log Analytics Workspace** – Centralizes log ingestion for streamlined monitoring and troubleshooting.

This setup ensures a **cost-effective, reliable, and secure** SonarQube deployment on Azure while providing **enhanced observability** through **automated log ingestion**.

## Highlights

- **Self-contained deployment** – No external dependencies beyond basic networking.
- **Private Deployment** – The entire infrastructure is **deployed in a private network**, with external access routed exclusively through the **Application Gateway**.
- **Persistence** – Three file shares are used to persist data, extensions, and logs. This improves **internal Elasticsearch cache performance**, allows **easy integration of third-party plugins**, and **prevents logs** from consuming container space.
- **Automated Logging** – Logs are ingested automatically into **Azure Log Analytics** for easy troubleshooting and monitoring.
- **Dedicated Container Registry** – Deploys and uses its **own container registry** to bypass Docker Hub’s pull rate limits.
- **Automated Image Handling** – The module automatically pulls the specified SonarQube image tag from **Docker Hub**, pushes it to the **private container registry**, and deploys it securely.

## Requirements

- Terraform v1.9+
- Azure CLI
- An Azure account with necessary permissions
- **Pre-existing networking infrastructure:** This module requires that the VNet, subnets, and networking resources are deployed beforehand.

## Inputs

| Name                          | Description                                                  | Type           | Default                | Required |
| ----------------------------- | ------------------------------------------------------------ | -------------- | ---------------------- | -------- |
| `name`                        | Name to be used on all resources as an identifier.           | `string`       | `"sonarqube"`          | no       |
| `tags`                        | A map of tags for resource organization and cost management. | `map(string)`  | `{}`                   | no       |
| `location`                    | Azure region where resources will be deployed.               | `string`       | `"northeurope"`        | no       |
| `resource_group_name`         | The name of the Azure resource group.                        | `string`       | N/A                    | yes      |
| `admins_allowed_ips`          | Mapping of admin users to their allowed public IPs.          | `map(string)`  | `{}`                   | no       |
| `vnet_id`                     | ID of the Virtual Network.                                   | `string`       | N/A                    | yes      |
| `subnet_private_endpoints_id` | The ID of the subnet used for private endpoints.             | `string`       | N/A                    | yes      |
| `subnet_pgsql_id`             | The ID of the subnet used for the PostgreSQL database.       | `string`       | N/A                    | yes      |
| `subnet_appgw_id`             | The ID of the subnet used for the Application Gateway.       | `string`       | N/A                    | yes      |
| `subnet_aci_id`               | The ID of the subnet used for the ACI.                       | `string`       | N/A                    | yes      |
| `keyvault`                    | Configuration for Azure Key Vault.                           | `object`       | See below              | no       |
| `kv_admins`                   | List of user IDs with admin privileges over Key Vault.       | `list(string)` | `[]`                   | no       |
| `storage_account`             | Configuration for the Azure Storage Account.                 | `object`       | See below              | no       |
| `sonar_db_server`             | The name of the SonarQube database server.                   | `string`       | `"sonardbserver"`      | no       |
| `sonar_db_instance_class`     | The instance class for the SonarQube database.               | `string`       | `"GP_Standard_D2s_v3"` | no       |
| `sonar_db_storage_type`       | The storage type for the SonarQube database.                 | `string`       | `"P10"`                | no       |
| `sonar_db_name`               | The name of the SonarQube database.                          | `string`       | `"sonar"`              | no       |
| `sonar_db_user`               | The username for the SonarQube database.                     | `string`       | `"sonar"`              | no       |
| `sonar_port`                  | The port on which SonarQube will run.                        | `number`       | `9000`                 | no       |
| `sonar_container_name`        | The name of the SonarQube container.                         | `string`       | `"sonarqube"`          | no       |
| `sonar_image_tag`             | The Docker Hub tag of the SonarQube image to deploy.         | `string`       | `"community"`          | no       |

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

### Security Considerations

To ensure secure access to key infrastructure components, the following sensitive variables should be populated properly:

- **`kv_admins`**: A list of Azure Active Directory (AAD) user IDs who should have administrative access to the Azure Key Vault.
- **`admins_allowed_ips`**: A mapping of admin names to their allowed public IP addresses, restricting remote access to sensitive services.

It is highly recommended to store these values in a **.tfvars** file instead of defining them directly in Terraform configuration files. This improves security and prevents accidental exposure in version control.

Example **`terraform.tfvars`**:

```hcl
kv_admins = ["11111111-2222-3333-4444-555555555555"]

admins_allowed_ips = {
    "Admin1" = "203.0.113.10"
    "Admin2" = "198.51.100.24"
}
```

Apply Terraform using the .tfvars file:

```sh
terraform apply -var-file="terraform.tfvars"
```

This ensures that the correct administrators have access to key resources while maintaining best security practices.

## Outputs

| Name       | Description                                                 | Value                                      |
| ---------- | ----------------------------------------------------------- | ------------------------------------------ |
| `aci_id`   | The ID of the Azure Container Instance hosting SonarQube.   | `azurerm_container_group.sonarqube.id`    |
| `aci_name` | The name of the Azure Container Instance hosting SonarQube. | `azurerm_container_group.sonarqube.name`  |
| `appgw_id` | The ID of the Application Gateway managing SonarQube traffic. | `azurerm_public_ip.appgw.id`              |
| `appgw_fqdn` | The fully qualified domain name (FQDN) of the Application Gateway public IP. | `azurerm_public_ip.appgw.fqdn` |

## Enabling HTTPS Support

This Terraform module does **not** include HTTPS (TLS) support in the Azure Application Gateway (AppGW) by default for the following reasons:

- **DNS & Certificate Complexity**: Automating HTTPS across all use cases is challenging. Different organizations use various **DNS providers, certificate authorities (CAs), and domain types**, some of which are not natively supported in certain cloud environments.  
- **Flexibility for Users**: HTTPS implementation varies based on **security policies, internal PKI infrastructure, and certificate lifecycle management**. Providing a one-size-fits-all approach could introduce unnecessary constraints.  
- **User Control**: Delegating TLS configuration allows users to integrate with **existing certificate automation workflows** and manage domain-specific requirements independently.  

### How to Enable HTTPS Manually

To introduce HTTPS support for your SonarQube deployment, follow these steps:

1. **Assign a Custom Domain**  
   - Ensure that your **Azure Application Gateway (AppGW)** is associated with a **custom domain name** (e.g., `sonarqube.example.com`).  
   - Update your **DNS provider** to point the domain to the **AppGW public IP**.  

2. **Generate or Import a TLS Certificate**  
   - If using **a public CA**, obtain an SSL certificate for your domain.  
   - If using **Azure Key Vault**, store and manage the certificate securely.  
   - Alternatively, you can generate a **self-signed certificate** for internal use.  

3. **Configure HTTPS Listener on Application Gateway**  
   - Update the **Application Gateway configuration** to:  
     - Create a **new HTTPS listener** on port **443**.  
     - Attach the generated/imported **TLS certificate**.  
     - Ensure that backend HTTP traffic is properly forwarded.  

By following these steps, users can enable HTTPS while maintaining flexibility over their **certificate management, domain setup, and security policies**.

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

  # SonarQube Configuration
  sonar_db_server          = "sonardbserver"
  sonar_db_instance_class  = "GP_Standard_D2ds_v4"
  sonar_db_storage_type    = "P20"
  sonar_db_name            = "sonar"
  sonar_db_user            = "sonar"
  sonar_port               = 9000
  sonar_container_name     = "sonarqube"
  sonar_image_tag          = "community"

  # Admin
  kv_admins                   = var.kv_admins
  admins_allowed_ips          = var.admins_allowed_ips
}
```

### Customizing SonarQube Version

You can specify a different version of the SonarQube Docker image by setting the `sonar_image_tag` variable:

```hcl
sonar_image_tag = "10.7.0-community"
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

[![banner](https://raw.githubusercontent.com/nearform/.github/refs/heads/master/assets/os-banner-green.svg)](https://www.nearform.com/contact/?utm_source=open-source&utm_medium=banner&utm_campaign=os-project-pages)
