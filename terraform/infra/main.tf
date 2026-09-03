terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State stored in Git alongside this code.
  # The GHA workflow commits the updated terraform.tfstate back after every apply.
  backend "local" {
    path = "terraform.tfstate"
  }
}

# When running in GitHub Actions, credentials come from OIDC via
# aws-actions/configure-aws-credentials (no static keys stored).
# When running locally, ambient AWS CLI credentials (cliuser) are used.
provider "aws" {
  region = var.aws_region
}
