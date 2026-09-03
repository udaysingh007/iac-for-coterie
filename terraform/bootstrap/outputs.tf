output "azure_client_id" {
  description = "App registration client ID — set as AZURE_CLIENT_ID in GitHub Actions"
  value       = azuread_application.gha_oidc.client_id
}

output "azure_tenant_id" {
  description = "Azure tenant ID"
  value       = var.tenant_id
}

output "azure_subscription_id" {
  description = "Azure subscription ID"
  value       = var.subscription_id
}

output "service_principal_object_id" {
  description = "Service principal object ID"
  value       = azuread_service_principal.gha_oidc.object_id
}
