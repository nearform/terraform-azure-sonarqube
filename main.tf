################################################################################
# Commons
################################################################################
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

resource "random_string" "resource_name_suffix" {
  length  = 6
  special = false
  upper   = false
}

################################################################################
# DNS Zones
################################################################################
## PostgreSQL DB server
resource "azurerm_private_dns_zone" "pgsql_server_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

## Storage Account
### Blob
resource "azurerm_private_dns_zone" "sa_blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

### File
resource "azurerm_private_dns_zone" "sa_file_dns" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

## Key Vault
resource "azurerm_private_dns_zone" "keyvault_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

################################################################################
# Virtual Links to private DNS zones
################################################################################
## PostgreSQL DB server
resource "azurerm_private_dns_zone_virtual_network_link" "pgsql_server_vnetlink" {
  name                  = "${var.name}pgsqlvnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.pgsql_server_dns.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
}

## Storage Account
### Blob
resource "azurerm_private_dns_zone_virtual_network_link" "sa_blob_vnetlink" {
  name                  = "${var.name}sablobvnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.sa_blob_dns.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
}

### File
resource "azurerm_private_dns_zone_virtual_network_link" "sa_file_vnetlink" {
  name                  = "${var.name}safilevnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.sa_file_dns.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
}

## Key Vault
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_vnetlink" {
  name                  = "${var.name}keyvaultvnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.keyvault_dns.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
}

################################################################################
# Azure Container Registry
################################################################################
resource "azurerm_container_registry" "sonarqube" {
  name                          = "${var.name}${random_string.resource_name_suffix.result}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "Standard"
  admin_enabled                 = true
  public_network_access_enabled = true
  tags                          = var.tags
}

# Authenticate to ACR, pull the public image from Docker Hub, tag it, and push to ACR
resource "null_resource" "sonar_image_pull_tag_push" {
  depends_on = [azurerm_container_registry.sonarqube]

  provisioner "local-exec" {
    command = <<EOT
      az acr login --name ${azurerm_container_registry.sonarqube.name}
      docker pull sonarqube:${var.sonar_image_tag} --platform=linux/amd64
      docker tag sonarqube:${var.sonar_image_tag} ${azurerm_container_registry.sonarqube.login_server}/sonarqube:${var.sonar_image_tag}
      docker push ${azurerm_container_registry.sonarqube.login_server}/sonarqube:${var.sonar_image_tag} --platform=linux/amd64
      docker rmi sonarqube:${var.sonar_image_tag} ${azurerm_container_registry.sonarqube.login_server}/sonarqube:${var.sonar_image_tag}
    EOT
  }
}

################################################################################
# KeyVault
################################################################################
locals {
  kv_secret_permissions_admin = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
  ]
  kv_secret_permissions_user = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
  ]
  kv_days_to_hours = var.keyvault.secret_expiration_days * 24
}

resource "azurerm_key_vault" "keyvault" {
  name                          = "${var.name}keyvault"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku_name                      = var.keyvault.sku
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days    = var.keyvault.soft_delete_period
  purge_protection_enabled      = var.keyvault.purge_protection
  public_network_access_enabled = true
  tags                          = var.tags
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [for ip in var.admins_allowed_ips : "${ip}/32"]
  }
}

# Key Vault access policies
resource "azurerm_key_vault_access_policy" "kv_policy_admin" {
  for_each           = toset(var.kv_admins)
  key_vault_id       = azurerm_key_vault.keyvault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = each.key
  secret_permissions = local.kv_secret_permissions_admin
}

# Private endpoint
resource "azurerm_private_endpoint" "keyvault_pe" {
  name                          = "${var.name}keyvault-pe"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  subnet_id                     = var.subnet_private_endpoints_id
  custom_network_interface_name = "${var.name}keyvault-pe-nic"
  tags                          = var.tags

  private_service_connection {
    name                           = "${var.name}keyvault-private-service-connection"
    private_connection_resource_id = azurerm_key_vault.keyvault.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault_dns.id]
  }
}

################################################################################
# SonarDB credentials
################################################################################
resource "random_password" "sonarqube_db_password" {
  length  = 16
  special = false
}

resource "azurerm_key_vault_secret" "sonarqube_db_password" {
  key_vault_id    = azurerm_key_vault.keyvault.id
  name            = "sonar-db-user-password"
  value           = random_password.sonarqube_db_password.result
  content_type    = "text/plain"
  expiration_date = timeadd(formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timestamp()), "${local.kv_days_to_hours}h")
  tags            = var.tags
  depends_on      = [azurerm_key_vault_access_policy.kv_policy_admin]
  lifecycle {
    ignore_changes = [
      expiration_date
    ]
  }
}

################################################################################
# PostgreSQL Flexible Server
################################################################################
resource "azurerm_postgresql_flexible_server" "sonarqube" {
  name                          = var.sonar_db_server
  location                      = var.location
  resource_group_name           = var.resource_group_name
  version                       = "16"
  public_network_access_enabled = false
  delegated_subnet_id           = var.subnet_pgsql_id
  private_dns_zone_id           = azurerm_private_dns_zone.pgsql_server_dns.id
  administrator_login           = var.sonar_db_user
  administrator_password        = azurerm_key_vault_secret.sonarqube_db_password.value
  storage_mb                    = 32768
  storage_tier                  = var.sonar_db_storage_type
  sku_name                      = var.sonar_db_instance_class
  zone                          = "1"
  tags                          = var.tags
  depends_on                    = [azurerm_private_dns_zone_virtual_network_link.pgsql_server_vnetlink]

  authentication {
    password_auth_enabled = true
  }
}

resource "azurerm_postgresql_flexible_server_database" "sonarqube" {
  name      = var.sonar_db_name
  server_id = azurerm_postgresql_flexible_server.sonarqube.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

################################################################################
# Storage Account
################################################################################
resource "azurerm_storage_account" "sonarqube" {
  name                          = "${var.name}${random_string.resource_name_suffix.result}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  account_kind                  = var.storage_account.account_kind
  account_tier                  = var.storage_account.account_tier
  account_replication_type      = var.storage_account.account_replication_type
  https_traffic_only_enabled    = var.storage_account.https_traffic_only_enabled
  min_tls_version               = var.storage_account.min_tls_version
  public_network_access_enabled = true
  sftp_enabled                  = var.storage_account.sftp_enabled
  is_hns_enabled                = var.storage_account.is_hns_enabled

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = [for ip in var.admins_allowed_ips : ip]
    virtual_network_subnet_ids = [
      var.subnet_aci_id,
      var.subnet_private_endpoints_id
    ]
  }

  blob_properties {
    delete_retention_policy {
      days = var.storage_account.blob_soft_delete_period
    }
    container_delete_retention_policy {
      days = var.storage_account.container_soft_delete_period
    }
  }
}

# Private endpoint (blob)
resource "azurerm_private_endpoint" "sa_blob_pe" {
  name                          = "${var.name}sablob-pe"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  subnet_id                     = var.subnet_private_endpoints_id
  custom_network_interface_name = "${var.name}sablob-pe-nic"
  tags                          = var.tags

  private_service_connection {
    name                           = "${var.name}sablob-private-service-connection"
    private_connection_resource_id = azurerm_storage_account.sonarqube.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_blob_dns.id]
  }
}

# Private endpoint (file)
resource "azurerm_private_endpoint" "sa_file_pe" {
  name                          = "${var.name}safile-pe"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  subnet_id                     = var.subnet_private_endpoints_id
  custom_network_interface_name = "${var.name}safile-pe-nic"
  tags                          = var.tags

  private_service_connection {
    name                           = "${var.name}safile-private-service-connection"
    private_connection_resource_id = azurerm_storage_account.sonarqube.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sa_file_dns.id]
  }
}

# File shares
resource "azurerm_storage_share" "sonarqube_data" {
  name               = "${var.name}datashare"
  storage_account_id = azurerm_storage_account.sonarqube.id
  quota              = 5
}

resource "azurerm_storage_share" "sonarqube_extensions" {
  name               = "${var.name}extensionsshare"
  storage_account_id = azurerm_storage_account.sonarqube.id
  quota              = 1
}

resource "azurerm_storage_share" "sonarqube_logs" {
  name               = "${var.name}logsshare"
  storage_account_id = azurerm_storage_account.sonarqube.id
  quota              = 5
}

################################################################################
# Azure Container Instance
################################################################################
resource "azurerm_container_group" "sonarqube" {
  name                = "${var.name}${random_string.resource_name_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_address_type     = "Private"
  subnet_ids          = [var.subnet_aci_id]
  os_type             = "Linux"
  tags                = var.tags

  exposed_port = [
    {
      port     = var.sonar_port
      protocol = "TCP"
    }
  ]

  container {
    name         = var.sonar_container_name
    image        = "${azurerm_container_registry.sonarqube.login_server}/${var.sonar_container_name}:${var.sonar_image_tag}"
    cpu          = 2
    cpu_limit    = 0
    memory       = 6
    memory_limit = 0
    ports {
      port     = var.sonar_port
      protocol = "TCP"
    }
    environment_variables = {
      SONAR_SEARCH_JAVAADDITIONALOPTS   = "-Dnode.store.allow_mmap=false,-Ddiscovery.type=single-node"
      SONAR_WEB_CONTEXT                 = "/"
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE = true
    }
    secure_environment_variables = {
      SONAR_JDBC_USERNAME = var.sonar_db_user
      SONAR_JDBC_PASSWORD = azurerm_key_vault_secret.sonarqube_db_password.value
      SONAR_JDBC_URL      = format("jdbc:postgresql://%s:5432/%s?sslmode=require", azurerm_postgresql_flexible_server.sonarqube.fqdn, azurerm_postgresql_flexible_server_database.sonarqube.name)
    }
    volume {
      name                 = "sonar-data"
      mount_path           = "/opt/sonarqube/data"
      storage_account_name = azurerm_storage_account.sonarqube.name
      storage_account_key  = azurerm_storage_account.sonarqube.primary_access_key
      share_name           = azurerm_storage_share.sonarqube_data.name
    }
    volume {
      name                 = "sonar-extensions"
      mount_path           = "/opt/sonarqube/extensions"
      storage_account_name = azurerm_storage_account.sonarqube.name
      storage_account_key  = azurerm_storage_account.sonarqube.primary_access_key
      share_name           = azurerm_storage_share.sonarqube_extensions.name
    }
    volume {
      name                 = "sonar-logs"
      mount_path           = "/opt/sonarqube/logs"
      storage_account_name = azurerm_storage_account.sonarqube.name
      storage_account_key  = azurerm_storage_account.sonarqube.primary_access_key
      share_name           = azurerm_storage_share.sonarqube_logs.name
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.sonarqube.id
    ]
  }

  image_registry_credential {
    user_assigned_identity_id = azurerm_user_assigned_identity.sonarqube.id
    server                    = azurerm_container_registry.sonarqube.login_server
  }

  diagnostics {
    log_analytics {
      workspace_id  = azurerm_log_analytics_workspace.sonarqube.workspace_id
      workspace_key = azurerm_log_analytics_workspace.sonarqube.primary_shared_key
    }
  }
}

resource "azurerm_user_assigned_identity" "sonarqube" {
  name                = "${var.name}acrsonarqube"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "sonarqube2acr" {
  scope                = azurerm_container_registry.sonarqube.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.sonarqube.principal_id
}

################################################################################
# Public IP Adress
################################################################################
resource "azurerm_public_ip" "appgw" {
  name                = "${var.name}${random_string.resource_name_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  domain_name_label   = "${var.name}${random_string.resource_name_suffix.result}"
  sku                 = "Standard"
  sku_tier            = "Regional"
  ip_version          = "IPv4"
  zones = [
    "1",
    "2",
    "3",
  ]
  tags = var.tags
}

################################################################################
# Application Gateway
################################################################################
locals {
  backend_address_pool_name      = "backendAppPool"
  frontend_http_port_name        = "frontendHttpPort"
  frontend_ip_configuration_name = "frontendIpConfiguration"
  gateway_ip_configuration_name  = "gatewayIpConfiguration"
  backend_http_setting_name      = "backendHttpSettings"
  http_listener_name             = "httpListener"
  request_routing_http_rule_name = "routingRuleHttp80"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.name}appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  enable_http2        = true
  firewall_policy_id  = null

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.appgw.id
    ]
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = var.subnet_appgw_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = local.frontend_http_port_name
    port = 80
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = [azurerm_container_group.sonarqube.ip_address]
  }

  backend_http_settings {
    name                                = local.backend_http_setting_name
    cookie_based_affinity               = "Disabled"
    pick_host_name_from_backend_address = false
    port                                = 9000
    protocol                            = "Http"
    request_timeout                     = 20
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_http_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_http_rule_name
    http_listener_name         = local.http_listener_name
    priority                   = 10
    rule_type                  = "Basic"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_setting_name
  }

  tags       = var.tags
  depends_on = [azurerm_key_vault_access_policy.kv_policy_appgw]
}

# AppGw user assigned identity
resource "azurerm_user_assigned_identity" "appgw" {
  name                = "${var.name}appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "appgw2kv" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.appgw.principal_id
}

resource "azurerm_key_vault_access_policy" "kv_policy_appgw" {
  key_vault_id       = azurerm_key_vault.keyvault.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_user_assigned_identity.appgw.principal_id
  secret_permissions = local.kv_secret_permissions_user
}

################################################################################
# AppInsights Workspace
################################################################################
resource "azurerm_log_analytics_workspace" "sonarqube" {
  name                = "${var.name}${random_string.resource_name_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018" # cannot be changed as per https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace?WT.mc_id=enterprise-0000-shkuehn#sku-1
  retention_in_days   = 30
  daily_quota_gb      = 5
}
