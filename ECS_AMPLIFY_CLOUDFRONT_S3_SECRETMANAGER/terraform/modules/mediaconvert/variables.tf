variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "LiveDemo"
}

variable "environment" {
  description = "Environment name (dev, prod, etc.)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for video storage"
  type        = string
}

variable "notification_endpoint" {
  description = "HTTPS endpoint for SNS notifications (optional)"
  type        = string
  default     = null
} 

variable "mediaconvert_endpoint" {
  description = "endpoint for MediaConvert (optional)"
  type        = string
  default     = null
}