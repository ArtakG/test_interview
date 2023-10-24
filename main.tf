locals {
  common_tags = {
    environment = "prod"
    project     = "interview"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.short_location}-rg"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "standard" {
  name                     = "${var.prefix}${var.short_location}standard"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

resource "azurerm_app_service_plan" "this" {
  name                = "${var.prefix}${var.short_location}-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  lifecycle {
    ignore_changes = [
      kind
    ]
  }
  tags = local.common_tags
}

resource "azurerm_function_app" "this" {
  name                       = "${var.prefix}${var.short_location}-function"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.this.id
  storage_account_name       = azurerm_storage_account.standard.name
  storage_account_access_key = azurerm_storage_account.standard.primary_access_key
  os_type                    = "linux"
  version                    = "~4"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "python"
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.test.instrumentation_key}"
  }

  site_config {
    linux_fx_version = "python|3.9"
  }
}

resource "azurerm_application_insights" "test" {
  name                = "${var.prefix}${var.short_location}-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_key_vault" "lz_kv" {
  name                        = "${var.prefix}-${var.short_location}-kv"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true

  sku_name = "standard"
}

resource "azurerm_key_vault_secret" "standard_key" {
  name         = "azurestorageaccountkey"
  value        = azurerm_storage_account.standard.primary_access_key
  key_vault_id = azurerm_key_vault.lz_kv.id
  depends_on   = [azurerm_role_assignment.this]
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "this" {
  scope                = azurerm_key_vault.lz_kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
  depends_on           = [azurerm_key_vault.lz_kv]
}