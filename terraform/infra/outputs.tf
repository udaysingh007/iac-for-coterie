output "public_ip_address" {
  description = "VM public IP — use this to SSH or reach services directly"
  value       = azurerm_public_ip.main.ip_address
}

output "fqdn" {
  description = "Free Azure DNS FQDN: <vm_name>.<region>.cloudapp.azure.com"
  value       = azurerm_public_ip.main.fqdn
}

output "ssh_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "k3s_kubeconfig_command" {
  description = "Command to copy kubeconfig from the VM to your local machine"
  value       = "scp ${var.admin_username}@${azurerm_public_ip.main.ip_address}:/home/${var.admin_username}/.kube/config ~/.kube/coterie-config"
}

output "grafana_url" {
  description = "Grafana URL (after you deploy it to the cluster)"
  value       = "http://${azurerm_public_ip.main.fqdn}:3000"
}
