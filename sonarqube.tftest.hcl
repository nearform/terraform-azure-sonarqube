# Credential-free compliance checks for the SonarQube module.
# Replaces terraform-compliance BDD features (features/*.feature) using native
# Terraform mocking — no Azure subscription or emulator required.

mock_provider "azurerm" {}

override_data {
  target = data.azurerm_client_config.current
  values = {
    tenant_id       = "00000000-0000-0000-0000-000000000001"
    client_id       = "00000000-0000-0000-0000-000000000002"
    object_id       = "00000000-0000-0000-0000-000000000003"
    subscription_id = "00000000-0000-0000-0000-000000000000"
  }
  override_during = plan
}

override_data {
  target = data.azurerm_subscription.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
  }
  override_during = plan
}

variables {
  sonar_image_tag             = "10.7.0-community"
  resource_group_name         = "rg-sonarqube-test"
  vnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sonarqube-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
  subnet_private_endpoints_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sonarqube-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/private-endpoints"
  subnet_pgsql_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sonarqube-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/pgsql"
  subnet_appgw_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sonarqube-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/appgw"
  subnet_aci_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sonarqube-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/aci"
}

run "plan_and_verify_module" {
  command = plan

  # ACR — features/aci.feature
  assert {
    condition     = azurerm_container_registry.sonarqube.sku == "Basic"
    error_message = "Container registry SKU must be Basic."
  }

  assert {
    condition     = azurerm_container_registry.sonarqube.admin_enabled == true
    error_message = "Container registry admin access must be enabled."
  }

  assert {
    condition     = azurerm_management_lock.sonarqube_acr.lock_level == "CanNotDelete"
    error_message = "Container registry must have a CanNotDelete management lock."
  }

  # PostgreSQL — features/postgres.feature
  assert {
    condition     = azurerm_postgresql_flexible_server.sonarqube.public_network_access_enabled == false
    error_message = "PostgreSQL server must not allow public network access."
  }

  assert {
    condition     = azurerm_postgresql_flexible_server.sonarqube.authentication[0].password_auth_enabled == true
    error_message = "PostgreSQL server must have password authentication enabled."
  }

  assert {
    condition     = azurerm_management_lock.sonarqube_pgsql.lock_level == "CanNotDelete"
    error_message = "PostgreSQL server must have a CanNotDelete management lock."
  }

  # Application Gateway — features/app-gw.feature
  assert {
    condition     = azurerm_application_gateway.sonarqube.enable_http2 == true
    error_message = "Application Gateway must have HTTP/2 enabled."
  }

  assert {
    condition     = azurerm_application_gateway.sonarqube.sku[0].tier == "Basic"
    error_message = "Application Gateway SKU tier must be Basic."
  }

  assert {
    condition     = azurerm_application_gateway.sonarqube.identity[0].type == "UserAssigned"
    error_message = "Application Gateway must use a user-assigned managed identity."
  }

  assert {
    condition     = azurerm_management_lock.sonarqube_appgw.lock_level == "CanNotDelete"
    error_message = "Application Gateway must have a CanNotDelete management lock."
  }

  # Key Vault — features/kv.feature
  assert {
    condition     = azurerm_key_vault.keyvault.network_acls[0].default_action == "Deny"
    error_message = "Key Vault network ACL default action must be Deny."
  }

  # Storage Account — features/storage-account.feature
  assert {
    condition     = azurerm_storage_account.sonarqube.network_rules[0].default_action == "Deny"
    error_message = "Storage account network rules default action must be Deny."
  }

  assert {
    condition     = contains(azurerm_storage_account.sonarqube.network_rules[0].virtual_network_subnet_ids, var.subnet_aci_id)
    error_message = "Storage account must allow traffic from the ACI subnet."
  }

  assert {
    condition     = contains(azurerm_storage_account.sonarqube.network_rules[0].virtual_network_subnet_ids, var.subnet_private_endpoints_id)
    error_message = "Storage account must allow traffic from the private endpoints subnet."
  }
}
