# ---------------------------------------------------------------------------
# Azure AD App Registration + Service Principal for GitHub Actions OIDC
# ---------------------------------------------------------------------------

resource "azuread_application" "gha_oidc" {
  display_name = var.app_display_name
}

resource "azuread_service_principal" "gha_oidc" {
  client_id                    = azuread_application.gha_oidc.client_id
  app_role_assignment_required = false
}

# Federated credential — trusts pushes/merges to main
resource "azuread_application_federated_identity_credential" "main_branch" {
  application_id = azuread_application.gha_oidc.id
  display_name   = "iac-for-coterie-main"
  description    = "GitHub Actions OIDC — main branch"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
  audiences      = ["api://AzureADTokenExchange"]
}

# Federated credential — trusts pull-request workflows
resource "azuread_application_federated_identity_credential" "pr" {
  application_id = azuread_application.gha_oidc.id
  display_name   = "iac-for-coterie-pr"
  description    = "GitHub Actions OIDC — pull requests"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repo}:pull_request"
  audiences      = ["api://AzureADTokenExchange"]
}

# ---------------------------------------------------------------------------
# Contributor role assignment on the subscription
# ---------------------------------------------------------------------------

resource "azurerm_role_assignment" "gha_contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.gha_oidc.object_id
}

# ---------------------------------------------------------------------------
# GitHub Actions repo variables (non-sensitive — no secrets needed for OIDC)
# ---------------------------------------------------------------------------

resource "github_actions_variable" "azure_client_id" {
  repository    = var.github_repo
  variable_name = "AZURE_CLIENT_ID"
  value         = azuread_application.gha_oidc.client_id
}

resource "github_actions_variable" "azure_tenant_id" {
  repository    = var.github_repo
  variable_name = "AZURE_TENANT_ID"
  value         = var.tenant_id
}

resource "github_actions_variable" "azure_subscription_id" {
  repository    = var.github_repo
  variable_name = "AZURE_SUBSCRIPTION_ID"
  value         = var.subscription_id
}
