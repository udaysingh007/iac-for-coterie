output "oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN — set as AWS_ROLE_ARN in GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "aws_region" {
  value = var.aws_region
}

output "aws_account_id" {
  value = var.aws_account_id
}
