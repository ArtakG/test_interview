terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.77.0"
    }
  }
  backend "azurerm" {
    storage_account_name = "satcgterraform"
    container_name       = "state"
    key                  = "terraform/temp"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }

  subscription_id = var.subscription_id
  #  tenant_id       = var.tenant_id
}