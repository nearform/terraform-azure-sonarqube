Feature: Test Azure Container Registry

    Scenario: Ensure the ACI has a Basic sku
        Given I have azurerm_container_registry defined
        Then it must contain sku
        And its value must be Basic

    Scenario: Ensure admin feature is enabled
        Given I have azurerm_container_registry defined
        Then it must contain admin_enabled
        And its value must be true
