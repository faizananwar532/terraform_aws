variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
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

# AWS Configuration
variable "aws_access_key_id" {
  description = "aws access key to be used by Agora for s3"
  type        = string
}

variable "aws_secret_access_key" {
  description = "aws secretaccess key to be used by Agora for s3"
  type        = string
}

variable "aws_bucket_name" {
  description = "AWS S3 Bucket Name"
  type        = string
}

variable "aws_bucket_name_for_cloud" {
  description = "AWS S3 Bucket Name for Cloud"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "cdn_url" {
  description = "CloudFront CDN URL"
  type        = string
}

variable "aws_cloudfront_distribution_id" {
  description = "AWS CloudFront Distribution ID"
  type        = string
}

# Media Convert Configuration
variable "mediaconvert_endpoint" {
  description = "MediaConvert Endpoint"
  type        = string
}

variable "mediaconvert_queue_arn" {
  description = "MediaConvert Queue ARN"
  type        = string
}

variable "mediaconvert_role_arn" {
  description = "MediaConvert Role ARN"
  type        = string
}

variable "sns_role_arn" {
  description = "SNS Role ARN"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN"
  type        = string
}
