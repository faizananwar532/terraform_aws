# IAM role for Amplify
resource "aws_iam_role" "amplify_role" {
  name = "${var.project_name}-${var.environment}-amplify-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "amplify.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for Amplify
resource "aws_iam_role_policy" "amplify_policy" {
  name = "${var.project_name}-${var.environment}-amplify-policy"
  role = aws_iam_role.amplify_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Frontend App
resource "aws_amplify_app" "frontend" {
  name                        = "${var.project_name}-frontend-${var.environment}"
  repository                  = var.frontend_repository
  access_token                = var.github_token
  enable_branch_auto_build    = true
  enable_branch_auto_deletion = true

  environment_variables = merge(
    var.frontend_environment_variables,
    {
      REACT_APP_API_ENDPOINT     = var.api_endpoint
      REACT_APP_ENV              = var.environment
      REACT_APP_API_URL          = var.environment == "prod" ? "https://api.${var.domain_name}" : "https://api-${var.environment}.${var.domain_name}"
      REACT_APP_frontend_SENTRY_DSN = var.frontend_sentry_dsn
    }
  )

  # Custom rewrite rules for SPA routing
  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404-200"
    condition = null
  }

  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|ttf|map|json)$)([^.]+$)/>"
    target = "/index.html"
    status = "200"
    condition = null
  }

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: build
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT
}

# frontend App - Main branch configuration
resource "aws_amplify_branch" "frontend_main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = var.branch_name
  framework   = "React"
  stage       = "PRODUCTION"
  # stage       = var.environment == "prod" ? "PRODUCTION" : "DEVELOPMENT"
  enable_auto_build = var.environment == "prod" ? false : true  # Disable automatic builds only for prod
}

# Domain associations commented out - configure manually in Amplify console
# resource "aws_amplify_domain_association" "frontend" {
#   app_id      = aws_amplify_app.frontend.id
#   domain_name = var.environment == "prod" ? "frontend.${var.domain_name}" : "frontend-${var.environment}.${var.domain_name}"

#   sub_domain {
#     branch_name = aws_amplify_branch.frontend_main.branch_name
#     prefix      = ""
#   }
# }

# Webhooks for automatic deployments
resource "aws_amplify_webhook" "frontend_main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = aws_amplify_branch.frontend_main.branch_name
  description = "Webhook for frontend app ${aws_amplify_branch.frontend_main.branch_name} branch"
}
 