variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
}

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"
}

variable "custom_domain_names" {
  description = "List of custom domain names for CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate for custom domain"
  type        = string
  default     = null
}

variable "min_ttl" {
  description = "Minimum TTL for cached objects"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default TTL for cached objects"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum TTL for cached objects"
  type        = number
  default     = 86400
} 

variable "agora_s3_user_arn" {
  description = "ARN of the Agora S3 user"
  type        = string
}
