# Secrets Manager resources
resource "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.project_name}-${var.environment}-app-secrets"
  description = "Application secrets for ${var.project_name} ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Initial secret values
resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  
  secret_string = jsonencode({
    # App Configuration
    PORT             = var.port
    SECRET           = var.jwt_secret
    DB_URL           = var.mongodb_url

    # AWS Configuration
    AWS_ACCESS_KEY_ID              = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY          = var.aws_secret_access_key
    AWS_BUCKET_NAME                = var.aws_bucket_name
    AWS_BUCKET_NAME_FOR_CLOUD      = var.aws_bucket_name_for_cloud
    AWS_REGION                     = var.aws_region
    CDN_URL                        = var.cdn_url
    AWS_CLOUDFRONT_DISTRIBUTION_ID = var.aws_cloudfront_distribution_id

    # Media Convert Configuration
    MEDIACONVERT_ENDPOINT    = var.mediaconvert_endpoint
    MEDIACONVERT_QUEUE_ARN   = var.mediaconvert_queue_arn
    MEDIACONVERT_ROLE_ARN    = var.mediaconvert_role_arn
    SNS_ROLE_ARN             = var.sns_role_arn
    SNS_TOPIC_ARN            = var.sns_topic_arn
  })
} 