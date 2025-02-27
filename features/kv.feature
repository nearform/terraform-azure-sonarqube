Feature: Test Azure Key Vault

    Scenario: Ensure the key vault has deny network acl in place
        Given I have azurerm_key_vault defined
        Then it must contain network_acls
        And it must have default_action
        Then its value must be Deny

