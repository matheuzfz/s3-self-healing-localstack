output "production_bucket_name" {
  description = "Production bucket name"
  value       = aws_s3_bucket.production.id
}

output "backup_bucket_name" {
  description = "Backup bucket name"
  value       = aws_s3_bucket.backup.id
}

output "sns_topic_arn" {
  description = "ARN SNS Alerts"
  value       = aws_sns_topic.alerts.arn
}

output "lambda_function_name" {
  description = "Lambda function recovery name"
  value       = aws_lambda_function.healer.function_name
}