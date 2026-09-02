terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }

  # State stored in Git alongside this code.
  # The GHA workflow commits the updated terraform.tfstate back after every apply.
  backend "local" {
    path = "terraform.tfstate"
  }
}

# When running in GitHub Actions, ARM_USE_OIDC=true and ARM_CLIENT_ID /
# ARM_TENANT_ID / ARM_SUBSCRIPTION_ID are injected by the workflow.
# When running locally, ambient `az login` credentials are used.
provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }
}
