# ---------------------------------------------------------------------------
# GitHub Actions OIDC provider (one per AWS account — idempotent)
# ---------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # Thumbprint list — GitHub's current TLS root CA thumbprint.
  # AWS validates OIDC tokens against this; update if GitHub rotates their CA.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1",
  "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# ---------------------------------------------------------------------------
# IAM role trusted by the iac-for-coterie repo (main branch + PRs)
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
  description        = "Role assumed by GitHub Actions OIDC for ${var.github_org}/${var.github_repo}"
}

# ---------------------------------------------------------------------------
# Permissions — EC2 + VPC full access is enough for the infra Terraform
# ---------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ec2_full" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "vpc_full" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# ---------------------------------------------------------------------------
# GitHub Actions repo variables (non-sensitive)
# ---------------------------------------------------------------------------

resource "github_actions_variable" "aws_region" {
  repository    = var.github_repo
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

resource "github_actions_variable" "aws_account_id" {
  repository    = var.github_repo
  variable_name = "AWS_ACCOUNT_ID"
  value         = var.aws_account_id
}

resource "github_actions_variable" "aws_role_arn" {
  repository    = var.github_repo
  variable_name = "AWS_ROLE_ARN"
  value         = aws_iam_role.github_actions.arn
}
