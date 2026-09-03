# ---------------------------------------------------------------------------
# Ubuntu 22.04 LTS AMI (latest, Canonical-owned)
# ---------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ---------------------------------------------------------------------------
# SSH key pair
# ---------------------------------------------------------------------------

resource "aws_key_pair" "main" {
  key_name   = "${var.name_prefix}-key"
  public_key = var.admin_ssh_public_key
  tags       = var.tags
}

# ---------------------------------------------------------------------------
# EC2 instance
# ---------------------------------------------------------------------------

resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vm.id]
  key_name               = aws_key_pair.main.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    delete_on_termination = true
  }

  # cloud-init: install k3s + Helm on first boot
  user_data = <<-CLOUDINIT
    #!/bin/bash
    set -e
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl wget git jq unzip apt-transport-https ca-certificates gnupg

    # Install k3s (single-node Kubernetes)
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    # Allow ubuntu user to use kubectl without sudo
    mkdir -p /home/${var.admin_username}/.kube
    cp /etc/rancher/k3s/k3s.yaml /home/${var.admin_username}/.kube/config
    chown -R ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/.kube
  CLOUDINIT

  tags = merge(var.tags, { Name = "${var.name_prefix}-vm" })
}

# ---------------------------------------------------------------------------
# Elastic IP (static public IP)
# ---------------------------------------------------------------------------

resource "aws_eip" "main" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name_prefix}-eip" })
}

resource "aws_eip_association" "main" {
  instance_id   = aws_instance.main.id
  allocation_id = aws_eip.main.id
}
