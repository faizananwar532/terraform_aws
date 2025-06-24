variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "The name of the project (e.g., demo)"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "prod"
}

variable "backend_service_name" {
  description = "Name of the backend service"
  type        = string
  default     = "value"
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "frontend_repository_url" {
  description = "Frontend repository URL"
  type        = string
}

variable "admin_repository_url" {
  description = "GitHub repository URL for the admin application"
  type        = string
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  sensitive   = true
}

# Network configuration specific to prod environment
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"  # Different CIDR for prod
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]  # Different CIDRs for prod
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24"]  # Different CIDRs for prod
} 

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "container_port" {
  description = "Container port"
  type        = string
}

# App Configuration
variable "port" {
  description = "Application port"
  type        = string
  default     = "5001"
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "mongodb_url" {
  description = "MongoDB connection URL"
  type        = string
  sensitive   = true
}

# Twilio Configuration
variable "twilio_account_sid" {
  description = "Twilio Account SID"
  type        = string
  sensitive   = true
}

variable "twilio_auth_token" {
  description = "Twilio Auth Token"
  type        = string
  sensitive   = true
}

variable "twilio_service_sid" {
  description = "Twilio Service SID"
  type        = string
  sensitive   = true
}

# AWS Configuration
variable "aws_bucket_name" {
  description = "AWS S3 Bucket Name"
  type        = string
}

variable "aws_bucket_name_for_cloud" {
  description = "AWS S3 Bucket Name for Cloud"
  type        = string
}

variable "cdn_url" {
  description = "CloudFront CDN URL"
  type        = string
}

variable "aws_cloudfront_distribution_id" {
  description = "AWS CloudFront Distribution ID"
  type        = string
}

# SendGrid Configuration
variable "sender_email" {
  description = "SendGrid Sender Email"
  type        = string
}

variable "receiver_email" {
  description = "SendGrid Receiver Email"
  type        = string
}

variable "sendgrid_key" {
  description = "SendGrid API Key"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Admin Email Address"
  type        = string
}

# Stripe Configuration
variable "stripe_secret_key" {
  description = "Stripe Secret Key"
  type        = string
  sensitive   = true
}

variable "stripe_publish_key" {
  description = "Stripe Publishable Key"
  type        = string
}

# Agora Configuration
variable "agora_app_id" {
  description = "Agora App ID"
  type        = string
  sensitive   = true
}

variable "agora_app_certificate" {
  description = "Agora App Certificate"
  type        = string
  sensitive   = true
}

variable "customer_key" {
  description = "Customer Key"
  type        = string
  sensitive   = true
}

variable "customer_secret" {
  description = "Customer Secret"
  type        = string
  sensitive   = true
}

# Pusher Configuration
variable "pusher_app_id" {
  description = "Pusher App ID"
  type        = string
}

variable "pusher_app_key" {
  description = "Pusher App Key"
  type        = string
}

variable "pusher_app_secret" {
  description = "Pusher App Secret"
  type        = string
  sensitive   = true
}

variable "pusher_app_cluster" {
  description = "Pusher App Cluster"
  type        = string
}

# Firebase Configuration
variable "firebase_project_id" {
  description = "Firebase Project ID"
  type        = string
}

variable "firebase_private_key_id" {
  description = "Firebase Private Key ID"
  type        = string
  sensitive   = true
}

variable "firebase_private_key" {
  description = "Firebase Private Key"
  type        = string
  sensitive   = true
}

variable "firebase_client_email" {
  description = "Firebase Client Email"
  type        = string
}

variable "firebase_client_id" {
  description = "Firebase Client ID"
  type        = string
}

variable "firebase_client_cert_url" {
  description = "Firebase Client Certificate URL"
  type        = string
}

# VOIP Configuration
variable "voip_key_id" {
  description = "VOIP Key ID"
  type        = string
}

variable "voip_team_id" {
  description = "VOIP Team ID"
  type        = string
}

variable "voip_bundle_id" {
  description = "VOIP Bundle ID"
  type        = string
}

variable "voip_key_path" {
  description = "VOIP Key Path"
  type        = string
}

# Wowza Configuration
variable "wowza_access_token" {
  description = "Wowza Access Token"
  type        = string
  sensitive   = true
}

# Apple Configuration
variable "apple_shared_secret" {
  description = "Apple Shared Secret"
  type        = string
  sensitive   = true
}

variable "frontend_sentry_dsn" {
  description = "Sentry DSN for frontend Dashboard error tracking"
  type        = string
  default     = "dsn here"
}

variable "admin_sentry_dsn" {
  description = "Sentry DSN for Admin Panel error tracking"
  type        = string
  default     = "dsn here"
}

variable "sentry_dsn" {
  description = "Sentry DSN"
  type        = string
}
 
variable "aws_access_key_id" {
  description = "aws access key to be used by Agora for s3"
  type        = string
}

variable "aws_secret_access_key" {
  description = "aws secretaccess key to be used by Agora for s3"
  type        = string
}

variable "agora_s3_user_arn" {
  description = "ARN of the Agora S3 user"
  type        = string
}