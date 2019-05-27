# -----------------------------------------------------------------
# AWS CREATE PYTHON LAMBDA FUNCTION - OUTPUTS
# -----------------------------------------------------------------

output "lambda_layer_arn" {
  description = "ARN of created Lambda Layer."
  value       = aws_lambda_layer_version.certbot_base.arn
}

output "lambda_layer_version" {
  description = "Version of created Lambda Layer."
  value       = aws_lambda_layer_version.certbot_base.version
}

output "lambda_name" {
  description = "Name assigned to the Lambda Function."
  value       = "${var.lambda_func_name}-${random_integer.id.result}"
}

output "lambda_arn" {
  description = "ARN of created Lambda Function."
  value       = var.lambda_publish_func ? aws_lambda_function.certbot_cloudflare.qualified_arn : aws_lambda_function.certbot_cloudflare.arn
}

output "lambda_version" {
  description = "Latest published version of Lambda Function."
  value       = aws_lambda_function.certbot_cloudflare.version
}

output "lambda_last_modified" {
  description = "The date the Lambda Function was last modified."
  value       = aws_lambda_function.certbot_cloudflare.last_modified
}

output "lambda_iam_role_id" {
  description = "Lambda IAM Role ID."
  value       = aws_iam_role.lambda_new_funct.id
}

output "lambda_iam_role_arn" {
  description = "Lambda IAM Role ARN."
  value       = aws_iam_role.lambda_new_funct.arn
}

output "cloudwatch_event_rule_arn" {
  description = "ARN of CloudWatch Trigger Event created to renew certificates."
  # value       = join("", aws_cloudwatch_event_rule.sched.*.arn)
  value = aws_cloudwatch_event_rule.sched[0].arn
}

