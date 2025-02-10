# terraform-azure-sonarqube

A Terraform module for deploying SonarQube on Azure using Azure Container Instances (ACI). This module automates the provisioning and management of SonarQube infrastructure in Azure, allowing easy deployment of SonarQube as a containerized service.

## Features

- Deploys SonarQube as a containerized service on Azure using Azure Container Instances (ACI).
- Configures necessary Azure resources such as a virtual network, container instance, and public IP address.
- Includes options for configuring SonarQube settings and persistent storage.
- Built with Terraform, enabling easy reuse and modification for different environments.

## Requirements

- Terraform vX.X.X or higher
- Azure account with necessary permissions and resources

## Inputs

| Name               | Description                                         | Type          | Default      | Required |
|--------------------|-----------------------------------------------------|---------------|--------------|----------|
| `instance_type`    | Size of the Azure container instance for SonarQube  | `string`      | `Standard_B2ms` | no     |
| `region`            | Azure region where the resources will be deployed   | `string`      | `eastus`     | no       |
| `sonarqube_version` | Version of SonarQube to deploy                      | `string`      | `latest`     | no       |
| `resource_group`    | Resource group for SonarQube deployment             | `string`      | N/A          | yes      |
| `vnet_name`         | Virtual network name for SonarQube deployment       | `string`      | N/A          | yes      |
| `subnet_id`         | Subnet ID for the SonarQube container instance      | `string`      | N/A          | yes      |
| `tags`              | Tags to assign to the created resources             | `map(string)` | `{}`         | no       |

## Outputs

| Name               | Description                                         |
|--------------------|-----------------------------------------------------|
| `sonarqube_url`     | The public URL to access SonarQube once deployed.   |
| `sonarqube_ip`      | The public IP address of the SonarQube instance.    |
| `aci_name`          | The name of the Azure Container Instance running SonarQube. |
| `container_group`   | The name of the container group in Azure.           |

## Examples

These examples demonstrate both a basic deployment and a custom configuration with additional parameters.

### Basic Usage

```hcl
module "sonarqube" {
  source            = "github.com/your-org/terraform-azure-sonarqube"
  region            = "eastus"
  instance_type     = "Standard_B2ms"
  sonarqube_version = "latest"
  resource_group    = "<your-resource-group>"
  vnet_name         = "<your-vnet-name>"
  subnet_id         = "<your-subnet-id>"
}
```

### Custom Configuration

```hcl
module "sonarqube" {
  source            = "github.com/your-org/terraform-azure-sonarqube"
  region            = "westus"
  instance_type     = "Standard_B2ms"
  sonarqube_version = "latest"
  resource_group    = "<your-resource-group>"
  vnet_name         = "<your-vnet-name>"
  subnet_id         = "<your-subnet-id>"
  tags = {
    Name        = "SonarQube Deployment"
    Environment = "Production"
  }
}
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
