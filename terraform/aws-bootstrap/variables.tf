variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = "365803995554"
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

variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  type        = string
  default     = "iac-for-coterie-gha-role"
}
