output "root_password" {
  value       = coalesce(var.user_password, random_password.user_password.result)
  sensitive   = true
}
