# frontend App Outputs
output "frontend_app_id" {
  description = "ID of the frontend Amplify app"
  value       = aws_amplify_app.frontend.id
}

output "frontend_app_arn" {
  description = "ARN of the frontend Amplify app"
  value       = aws_amplify_app.frontend.arn
}

output "frontend_default_domain" {
  description = "Default domain for the frontend Amplify app"
  value       = aws_amplify_app.frontend.default_domain
}

output "frontend_main_url" {
  description = "URL of the frontend main branch deployment"
  value       = "https://main.${aws_amplify_app.frontend.default_domain}"
}

output "frontend_webhook_url" {
  description = "Webhook URL for frontend app manual deployments"
  value       = aws_amplify_webhook.frontend_main.url
  sensitive   = true
}

output "frontend_branch_name" {
  description = "Name of the frontend app branch"
  value       = aws_amplify_branch.frontend_main.branch_name
}

# Domain outputs commented out - domains will be configured manually
# output "frontend_domain" {
#   description = "Domain name for the frontend app"
#   value       = var.environment == "prod" ? "https://frontend.${var.domain_name}" : "https://frontend-${var.environment}.${var.domain_name}"
# }
