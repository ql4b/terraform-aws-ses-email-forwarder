output "bucket_name" {
  value       = aws_s3_bucket.inbox.id
  description = "Name of the S3 bucket storing raw inbound messages"
}

output "bucket_arn" {
  value       = aws_s3_bucket.inbox.arn
  description = "ARN of the S3 bucket storing raw inbound messages"
}

output "lambda_function_name" {
  value       = module.forwarder.function_name
  description = "Name of the Lambda forwarder function"
}

output "lambda_function_arn" {
  value       = module.forwarder.function_arn
  description = "ARN of the Lambda forwarder function"
}

output "ses_rule_set_name" {
  value       = local.rule_set_name
  description = "Name of the SES receipt rule set"
}

output "ses_domain_identity_arn" {
  value       = var.create_identity ? aws_ses_domain_identity.this[0].arn : null
  description = "ARN of the SES domain identity, when created by this module"
}
