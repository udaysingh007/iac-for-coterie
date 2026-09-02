terraform {
  required_version = ">= 1.5"

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.3"
    }
  }

  # State stored in Git — fine for a single-developer, throwaway project.
  # Do NOT add terraform.tfstate to .gitignore for this directory.
  backend "local" {
    path = "terraform.tfstate"
  }
}

# Uses ambient `az login` credentials when run locally.
provider "azuread" {}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Reads GITHUB_TOKEN from the environment (set via `export GITHUB_TOKEN=$(gh auth token)`).
provider "github" {
  owner = var.github_org
}
