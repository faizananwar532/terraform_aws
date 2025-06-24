variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "backend_service_name" {
  description = "Name of the backend service"
  type        = string
} 