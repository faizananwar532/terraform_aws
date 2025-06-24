# S3 outputs
output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = module.s3.bucket_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.s3.cloudfront_domain_name
}

# MediaConverter outputs
output "mediaconvert_endpoint" {
  description = "MediaConverter endpoint URL"
  value       = module.mediaconvert.mediaconvert_endpoint
}

output "mediaconvert_queue_arn" {
  description = "MediaConverter queue ARN"
  value       = module.mediaconvert.mediaconvert_queue_arn
}

output "mediaconvert_role_arn" {
  description = "MediaConverter IAM role ARN"
  value       = module.mediaconvert.mediaconvert_role_arn
}

output "sns_role_arn" {
  description = "SNS IAM role ARN"
  value       = module.mediaconvert.sns_role_arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = module.mediaconvert.sns_topic_arn
}

# ECS outputs
output "api_cloudfront_domain_name" {
  description = "API CloudFront distribution domain name"
  value       = module.ecs.cloudfront_domain_name
}

# Amplify outputs
output "creator_app_url" {
  description = "Creator app URL"
  value       = module.amplify.creator_main_url
}

output "admin_app_url" {
  description = "Admin app URL"
  value       = module.amplify.admin_main_url
}

# GitHub Actions Deployment Outputs
output "prod_task_role_arn" {
  description = "ARN of the ECS task role for production deployment"
  value       = module.ecs.ecs_task_role_arn
}

output "prod_execution_role_arn" {
  description = "ARN of the ECS execution role for production deployment"
  value       = module.ecs.ecs_execution_role_arn
}

output "prod_secrets_arn" {
  description = "ARN of the AWS Secrets Manager secret for production deployment"
  value       = module.secrets.secrets_arn
}

output "prod_ecr_repository" {
  description = "Name of the ECR repository for production deployment"
  value       = module.ecr.repository_name
} 