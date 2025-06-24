output "mediaconvert_endpoint" {
  description = "MediaConvert endpoint URL for the current region"
  value       = local.mediaconvert_endpoint
}

output "mediaconvert_queue_arn" {
  description = "ARN of the MediaConvert queue"
  value       = local.queue_arn
}

output "mediaconvert_role_arn" {
  description = "ARN of the IAM role for MediaConvert"
  value       = local.mediaconvert_role_arn
}

output "sns_role_arn" {
  description = "ARN of the IAM role for SNS"
  value       = local.sns_role_arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for transcoding job notifications"
  value       = local.sns_topic_arn
} 