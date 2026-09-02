variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "010861c7-fcee-496f-b732-b852d41ab668"
}

variable "location" {
  description = "Azure region for all infra resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group that holds all infra"
  type        = string
  default     = "rg-coterie-vm"
}

variable "vm_name" {
  description = "Name of the virtual machine (also used as DNS label prefix)"
  type        = string
  default     = "coterie-vm"
}

variable "vm_size" {
  description = "Azure VM SKU — Standard_B2s gives 2 vCPU / 4 GB RAM at ~$0.05/hr"
  type        = string
  default     = "Standard_B2s"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

variable "admin_username" {
  description = "Admin username for SSH access"
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = <<-EOT
    SSH public key to authorise on the VM (contents of ~/.ssh/id_rsa.pub or similar).
    In GitHub Actions, set the secret ADMIN_SSH_PUBLIC_KEY and the workflow will
    pass it as TF_VAR_admin_ssh_public_key.
    Locally, add it to terraform/infra/terraform.tfvars (gitignored).
  EOT
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to every resource"
  type        = map(string)
  default = {
    project     = "coterie-assessment"
    environment = "dev"
    managed_by  = "terraform"
  }
}
