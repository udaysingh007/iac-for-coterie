resource "azurerm_network_interface" "main" {
  name                = "nic-coterie-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    name                 = "osdisk-coterie-vm"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  # Ubuntu 22.04 LTS Gen2
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # cloud-init: install common tools needed before the assessment workload
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - curl
      - wget
      - git
      - apt-transport-https
      - ca-certificates
      - gnupg
      - lsb-release
      - jq
      - unzip
    runcmd:
      # Install k3s (single-node Kubernetes)
      - curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
      # Install Helm
      - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      # Allow azureuser to use kubectl without sudo
      - mkdir -p /home/${var.admin_username}/.kube
      - cp /etc/rancher/k3s/k3s.yaml /home/${var.admin_username}/.kube/config
      - chown -R ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/.kube
      - sed -i 's|server: https://127.0.0.1:6443|server: https://127.0.0.1:6443|g' /home/${var.admin_username}/.kube/config
    CLOUDINIT
  )
}
