terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.3"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

# Uses ambient AWS CLI credentials (cliuser) when run locally.
provider "aws" {
  region = var.aws_region
}

# Reads GITHUB_TOKEN from the environment: export GITHUB_TOKEN=$(gh auth token)
provider "github" {
  owner = var.github_org
}
