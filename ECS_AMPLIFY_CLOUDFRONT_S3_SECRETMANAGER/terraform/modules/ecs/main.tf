# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = local.resource_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${local.resource_prefix}"
  retention_in_days = 7

  tags = local.common_tags
}

# Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.resource_prefix}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ALB
resource "aws_lb" "main" {
  name               = local.resource_prefix
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets           = var.public_subnet_ids

  tags = local.common_tags
}

# ALB Target Group
resource "aws_lb_target_group" "main" {
  name        = local.resource_prefix
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn  = aws_lb.main.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Task Definition Template - Initial deployment only
data "template_file" "task_definition" {
  template = file("../../task_definitions/${var.environment}.json")

  vars = {
    project_name           = var.project_name
    environment            = var.environment
    aws_region             = data.aws_region.current.name
    ecr_repository_url     = var.ecr_repository_url
    ecs_execution_role_arn = aws_iam_role.ecs_execution.arn
    ecs_task_role_arn      = aws_iam_role.ecs_task.arn
    app_secrets_arn        = data.aws_secretsmanager_secret.app_secrets.arn
    # Use latest tag for initial deployment - GitHub Actions will handle specific versions
    image_tag              = "latest"
  }
}

# Get the secrets ARN from secrets manager
data "aws_secretsmanager_secret" "app_secrets" {
  name = "${var.project_name}-${var.environment}-app-secrets"
}

# ECS Task Definition - Initial deployment only, GitHub Actions handles updates
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-${var.environment}"
  container_definitions    = data.template_file.task_definition.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.environment == "prod" ? 512 : 256
  memory                   = var.environment == "prod" ? 1024 : 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  # Ignore changes to container definitions since GitHub Actions will update them
  lifecycle {
    ignore_changes = [
      container_definitions,
      tags
    ]
  }

  tags = local.common_tags
}

# ECS Service - Initial deployment only, GitHub Actions handles task definition updates
resource "aws_ecs_service" "main" {
  name                               = local.resource_prefix
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.main.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  platform_version                  = "LATEST"
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${local.resource_prefix}-container"
    container_port   = var.container_port
  }

  # Ignore changes to task definition and desired count since GitHub Actions will manage deployments
  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
      tags
    ]
  }

  depends_on = [aws_lb_listener.http]

  tags = local.common_tags
}

# IP Set for allowed IPs (can be populated later if needed)
resource "aws_wafv2_ip_set" "allowed_ips" {
  name               = "${local.resource_prefix}-allowed-ips"
  description        = "Set of allowed IP addresses for demo API"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = []  # Add specific allowed IPs here if needed

  tags = local.common_tags
}

# IP Set for blocked IPs
resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "${local.resource_prefix}-blocked-ips"
  description        = "Set of blocked IP addresses for demo API" 
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = []  # Add specific blocked IPs here if needed

  tags = local.common_tags
}

# Regex pattern set for livedemo.com subdomains
resource "aws_wafv2_regex_pattern_set" "demo_domains" {
  name        = "${local.resource_prefix}-demo-domains"
  description = "Regex pattern for livedemo.com API subdomains"
  scope       = "CLOUDFRONT"

  regular_expression {
    regex_string = "^api(-[a-z]+)?\\.livedemo\\.com$"
  }

  tags = local.common_tags
}

# WAF Web ACL for CloudFront
resource "aws_wafv2_web_acl" "demo_api_acl" {
  name        = "${local.resource_prefix}-api-waf"
  description = "WAF rules for demo API CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}  # Allow by default, then apply specific rules
  }

  # Rule 1: Allow legitimate demo API domains
  rule {
    name     = "AllowdemoAPIDomains"
    priority = 1
    action {
      allow {}
    }
    
    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "host"
              }
            }
            positional_constraint = "EXACTLY"
            search_string         = "api.livedemo.com"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
        
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "host"
              }
            }
            positional_constraint = "EXACTLY"
            search_string         = "api-dev.livedemo.com"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
        
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.demo_domains.arn
            field_to_match {
              single_header {
                name = "host"
              }
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowdemoAPIDomains"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Block requests with blocked IPs
  rule {
    name     = "BlockMaliciousIPs"
    priority = 2
    action {
      block {}
    }
    
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.blocked_ips.arn
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockMaliciousIPs"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: AWS Managed Rules - Core ruleset for common web attacks
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3
    
    override_action {
      count {}  # Count mode initially to avoid false positives
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        
        # Exclude rules that might interfere with API operations
        rule_action_override {
          action_to_use {
            allow {}
          }
          name = "SizeRestrictions_BODY"  # Allow larger request bodies for content uploads
        }
        
        rule_action_override {
          action_to_use {
            count {}
          }
          name = "GenericRFI_BODY"  # Count instead of block for API requests
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: SQL Injection Protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 4
    
    override_action {
      none {}  # Block SQL injection attempts
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 5
    
    override_action {
      none {}  # Block known bad inputs
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule 6: Bot Control (for API protection)
  rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 6
    
    override_action {
      count {}  # Count mode to monitor bot traffic without blocking
    }
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
        
        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"  # Use common inspection level for cost efficiency
            enable_machine_learning = false  # Explicitly set to current AWS state
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rule 7: Rate-Based Rule - Block excessive requests per IP
  rule {
    name     = "RateBasedRule"
    priority = 7
    
    action {
      block {}
    }
    
    statement {
      rate_based_statement {
        limit              = 2000  # 2000 requests per 5-minute window (suitable for API)
        aggregate_key_type = "IP"
        
        # Only apply rate limiting to non-allowed IPs
        scope_down_statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.allowed_ips.arn
              }
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateBasedRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule 8: Block common attack tools
  rule {
    name     = "BlockAttackTools"
    priority = 8
    
    action {
      block {}
    }
    
    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            positional_constraint = "CONTAINS"
            search_string         = "sqlmap"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            positional_constraint = "CONTAINS"
            search_string         = "nikto"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
        statement {
          byte_match_statement {
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            positional_constraint = "CONTAINS"
            search_string         = "nessus"
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockAttackTools"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "demoAPIWAF"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  price_class         = "PriceClass_100"
  aliases             = var.environment == "prod" ? ["api.${var.domain_name}"] : ["api-${var.environment}.${var.domain_name}"]
  default_root_object = ""
  web_acl_id          = aws_wafv2_web_acl.demo_api_acl.arn

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = local.resource_prefix

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.resource_prefix
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    # Add default TTL settings
    min_ttl     = 0
    default_ttl = 0  # Disable caching for API endpoints
    max_ttl     = 0
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.common_tags
}

# IAM Roles
resource "aws_iam_role" "ecs_execution" {
  name = "${local.resource_prefix}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach the AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add Secrets Manager access policy
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${local.resource_prefix}-secrets-policy"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          data.aws_secretsmanager_secret.app_secrets.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task" {
  name = "${local.resource_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Add Secrets Manager access policy
resource "aws_iam_role_policy" "ecs_task_s3_policy" {
  name = "${local.resource_prefix}-s3-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-content",
          "arn:aws:s3:::${var.project_name}-${var.environment}-content/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = "*"
      }
    ]
  })
}

# Add MediaConvert permissions to ECS task role
resource "aws_iam_role_policy" "ecs_task_mediaconvert_policy" {
  name = "${local.resource_prefix}-mediaconvert-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mediaconvert:CreateJob",
          "mediaconvert:GetJob",
          "mediaconvert:ListJobs",
          "mediaconvert:CancelJob",
          "mediaconvert:DescribeEndpoints"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          var.mediaconvert_role_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-${var.environment}-content",
          "arn:aws:s3:::${var.project_name}-${var.environment}-content/*"
        ]
      }
    ]
  })
}

# Current region data source
data "aws_region" "current" {} 