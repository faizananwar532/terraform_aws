locals {
  # Standard naming convention: {project_name}-{service_name}-{environment}
  repository_name = "${var.project_name}-${var.backend_service_name}-${var.environment}"
}

resource "aws_ecr_repository" "backend" {
  name = local.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name        = local.repository_name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Repository policy to allow ECS to pull images
resource "aws_ecr_repository_policy" "pull_policy" {
  repository = aws_ecr_repository.backend.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPull"
        Effect = "Allow"
        Principal = {
          Service = "ecs.amazonaws.com"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
} 