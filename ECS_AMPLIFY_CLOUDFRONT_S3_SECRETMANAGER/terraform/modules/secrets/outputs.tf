output "secrets_arn" {
  description = "ARN of the AWS Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "secrets_name" {
  description = "Name of the AWS Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.name
} 