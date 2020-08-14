output "root_password" {
  value       = coalesce(var.password, random_password.password.result)
  sensitive   = true
}
