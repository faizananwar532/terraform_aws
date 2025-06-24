# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create SNS Topic for MediaConvert job notifications
resource "aws_sns_topic" "transcoding_job" {
  name = "${var.project_name}-${var.environment}-transcoding-job"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Optional SNS Topic Subscription for notifications
resource "aws_sns_topic_subscription" "transcoding_job_notification" {
  count     = var.notification_endpoint != null ? 1 : 0
  topic_arn = aws_sns_topic.transcoding_job.arn
  protocol  = "https"
  endpoint  = var.notification_endpoint
}

# IAM Role for MediaConvert service
resource "aws_iam_role" "mediaconvert_role" {
  name = "${var.project_name}-${var.environment}-mediaconvert-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "mediaconvert.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# IAM Policy for MediaConvert to access S3 and SNS
resource "aws_iam_role_policy" "mediaconvert_policy" {
  name = "${var.project_name}-${var.environment}-mediaconvert-policy"
  role = aws_iam_role.mediaconvert_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.transcoding_job.arn
      }
    ]
  })
}

# IAM Role for SNS service (for job status notifications)
resource "aws_iam_role" "sns_role" {
  name = "${var.project_name}-${var.environment}-transcoding-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Create MediaConvert Queue (Default queue is automatically available, but we'll create a custom one)
resource "aws_media_convert_queue" "default" {
  name   = "${var.project_name}-${var.environment}-queue"
  status = "ACTIVE"

  tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# Local values for MediaConvert endpoint
locals {
  # Account-specific MediaConvert endpoint discovered via CLI
  mediaconvert_endpoint = var.mediaconvert_endpoint
  
  # Generate the queue ARN
  queue_arn = aws_media_convert_queue.default.arn
  
  # Generate role ARNs
  mediaconvert_role_arn = aws_iam_role.mediaconvert_role.arn
  sns_role_arn         = aws_iam_role.sns_role.arn
  
  # SNS topic ARN
  sns_topic_arn = aws_sns_topic.transcoding_job.arn
} 