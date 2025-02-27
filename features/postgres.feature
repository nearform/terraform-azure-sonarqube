Feature: Test Azure Postgres

    Scenario: Ensure the postgres server public access is disabled
        Given I have azurerm_postgresql_flexible_server defined
        Then it must contain public_network_access_enabled
        Then its value must be false

    Scenario: Ensure the password auth is enabled
        Given I have azurerm_postgresql_flexible_server defined
        Then it must contain authentication
        And it must have password_auth_enabled
        Then its value must be true
