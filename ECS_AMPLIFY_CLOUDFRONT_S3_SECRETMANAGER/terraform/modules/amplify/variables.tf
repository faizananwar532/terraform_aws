variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
}

variable "domain_name" {
  description = "Base domain name"
  type        = string
}

variable "branch_name" {
  description = "Branch name to deploy"
  type        = string
  default     = "main"
}

variable "api_endpoint" {
  description = "API endpoint URL"
  type        = string
}

variable "frontend_repository" {
  description = "GitHub repository URL for frontend app"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "frontend_environment_variables" {
  description = "Additional environment variables for frontend app"
  type        = map(string)
  default     = {}
}

variable "frontend_sentry_dsn" {
  description = "Sentry DSN for frontend app"
  type        = string
}

locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Name        = local.resource_prefix
  }
} 