variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "010861c7-fcee-496f-b732-b852d41ab668"
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
  default     = "73a77596-c66f-4916-bc4f-9797cf679065"
}

variable "github_org" {
  description = "GitHub user or org that owns the iac-for-coterie repo"
  type        = string
  default     = "udaysingh007"
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix)"
  type        = string
  default     = "iac-for-coterie"
}

variable "app_display_name" {
  description = "Display name for the Azure AD app registration used for GitHub OIDC"
  type        = string
  default     = "iac-for-coterie-gha-oidc"
}
