variable "aws_region" {
  description = "AWS region for all infra resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type — t3.medium gives 2 vCPU / 4 GB at ~$0.047/hr"
  type        = string
  default     = "r6i.xlarge"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "admin_username" {
  description = "Default SSH username for Ubuntu AMIs"
  type        = string
  default     = "ubuntu"
}

variable "admin_ssh_public_key" {
  description = <<-EOT
    SSH public key to authorise on the instance (contents of ~/.ssh/coterie_vm_key.pub).
    In GitHub Actions, set the secret ADMIN_SSH_PUBLIC_KEY — the workflow passes it
    as TF_VAR_admin_ssh_public_key.
    Locally, export TF_VAR_admin_ssh_public_key="$(cat ~/.ssh/coterie_vm_key.pub)".
  EOT
  type        = string
  sensitive   = true
}

variable "name_prefix" {
  description = "Prefix applied to all resource names"
  type        = string
  default     = "coterie"
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
