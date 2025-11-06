terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.18, < 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 3.8"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2, < 3.3"
    }
  }
}
