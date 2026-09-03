output "public_ip" {
  description = "Elastic IP — use this to SSH or reach services directly"
  value       = aws_eip.main.public_ip
}

output "public_dns" {
  description = "AWS-assigned public DNS hostname"
  value       = aws_eip.main.public_dns
}

output "ssh_command" {
  description = "Ready-to-use SSH command"
  value       = "ssh -i ~/.ssh/coterie_vm_key ${var.admin_username}@${aws_eip.main.public_ip}"
}

output "k3s_kubeconfig_command" {
  description = "Copy kubeconfig from the instance to your local machine"
  value       = "scp -i ~/.ssh/coterie_vm_key ${var.admin_username}@${aws_eip.main.public_ip}:/home/${var.admin_username}/.kube/config ~/.kube/coterie-config"
}

output "grafana_url" {
  description = "Grafana URL (after deploying it to the cluster)"
  value       = "http://${aws_eip.main.public_ip}:3000"
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "ami_used" {
  description = "Ubuntu 22.04 AMI that was deployed"
  value       = data.aws_ami.ubuntu.id
}
