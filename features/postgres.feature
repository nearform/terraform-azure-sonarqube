Feature: Test Azure Postgres

    Scenario: Ensure the postgres server public access is disabled
        Given I have azurerm_postgresql_flexible_server sonarqube defined
        Then it must contain public_network_access_enabled
        Then its value must be false

    Scenario: Ensure the password auth is enabled
        Given I have azurerm_postgresql_flexible_server sonarqube defined
        Then it must contain authentication
        And it must have password_auth_enabled
        Then its value must be true

    Scenario: Ensure Postgres is protected with a lock
        Given I have azurerm_management_lock sonarqube_pgsql defined
        Then it must contain scope
        And its value must be azurerm_container_registry.sonarqube.id

    Scenario: Ensure Postgres is protected with a lock to avoid deletion
        Given I have azurerm_management_lock sonarqube_pgsql defined
        Then it must contain lock_level
        And its value must be CanNotDelete
