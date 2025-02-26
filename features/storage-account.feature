Feature: Test Azure storage account

    Scenario: Ensure the storage account deny traffic by default
        Given I have azurerm_storage_account defined
        Then it must contain network_rules
        And it must have default_action
        Then its value must be Deny

