Feature: Test Azure App gateway

    Scenario: Ensure the Azure app gateway has http2 enabled
        Given I have azurerm_application_gateway defined
        When its name is sonarqube
        Then it must contain enable_http2
        Then its value must be true

    Scenario: Ensure the Azure app gateway is deployed with a basic sku
        Given I have azurerm_application_gateway defined
        When its name is sonarqube
        Then it must contain sku
        And it must have name
        Then its value must be Basic

    Scenario: Ensure the Azure app gateway is deployed with an user assigned identity
        Given I have azurerm_application_gateway defined
        When its name is sonarqube
        Then it must contain identity
        And it must have type
        Then its value must be UserAssigned
