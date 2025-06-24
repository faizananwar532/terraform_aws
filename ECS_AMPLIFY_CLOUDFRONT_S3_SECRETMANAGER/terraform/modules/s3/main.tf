locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# S3 bucket for static content
resource "aws_s3_bucket" "content" {
  bucket = "${local.resource_prefix}-content"

  tags = merge(local.common_tags, {
    Name = "${local.resource_prefix}-content"
  })
}

# S3 bucket CORS configuration
resource "aws_s3_bucket_cors_configuration" "content" {
  bucket = aws_s3_bucket.content.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.allowed_origins
    expose_headers  = ["ETag", "x-amz-server-side-encryption", "x-amz-request-id", "x-amz-id-2"]
    max_age_seconds = 3000
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "content" {
  bucket = aws_s3_bucket.content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "content" {
  bucket = aws_s3_bucket.content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront origin access control
resource "aws_cloudfront_origin_access_control" "s3_origin" {
  name                              = "${local.resource_prefix}-s3-origin-access-control"
  description                       = "S3 bucket access control for ${local.resource_prefix}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class
  aliases             = var.custom_domain_names

  origin {
    domain_name              = aws_s3_bucket.content.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_origin.id
    origin_id                = "S3Origin"
  }

  # Cache behavior for media files
  ordered_cache_behavior {
    path_pattern     = "*/media-*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    compress              = true

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_arn != null ? [1] : []
    content {
      acm_certificate_arn      = var.acm_certificate_arn
      minimum_protocol_version = "TLSv1.2_2021"
      ssl_support_method       = "sni-only"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.acm_certificate_arn == null ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = local.common_tags
}

# S3 bucket policy for CloudFront access
resource "aws_s3_bucket_policy" "content" {
  bucket = aws_s3_bucket.content.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"]
        Resource = [
          "${aws_s3_bucket.content.arn}",
          "${aws_s3_bucket.content.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      },
      {
        Sid       = "AllowECSTaskAccess"
        Effect    = "Allow"
        Principal = {
          AWS = "*"  # This will be restricted by the condition
        }
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          "${aws_s3_bucket.content.arn}",
          "${aws_s3_bucket.content.arn}/*"
        ]
        Condition = {
          StringLike = {
            "aws:PrincipalArn": "arn:aws:iam::*:role/${var.project_name}-${var.environment}-*"
          }
        }
      },
      {
        Sid       = "AllowSpecificUserAccess"
        Effect    = "Allow"
        Principal = {
          AWS = var.agora_s3_user_arn
          # "arn:aws:iam::381940662809:user/Dev_Agora_S3"
        }
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          "${aws_s3_bucket.content.arn}",
          "${aws_s3_bucket.content.arn}/*"
        ]
      }
    ]
  })
}