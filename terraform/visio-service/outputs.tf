output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.visio_health.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.visio_health.arn
}

output "lambda_function_url" {
  description = "Lambda Function URL (public endpoint)"
  value       = aws_lambda_function_url.visio_health_url.function_url
}

output "health_endpoint" {
  description = "Health check endpoint URL"
  value       = "${aws_lambda_function_url.visio_health_url.function_url}health"
}

output "status_endpoint" {
  description = "Status endpoint URL"
  value       = "${aws_lambda_function_url.visio_health_url.function_url}status"
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "iam_role_arn" {
  description = "IAM Role ARN for the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}

# Frontend-specific outputs
output "visio_health_url" {
  description = "URL for frontend to check visio conference health"
  value       = "${aws_lambda_function_url.visio_health_url.function_url}health"
}

output "visio_base_url" {
  description = "Visio service base URL"
  value       = aws_lambda_function_url.visio_health_url.function_url
}

output "frontend_env_variable" {
  description = "Complete environment variable for frontend .env file"
  value       = "NEXT_PUBLIC_VISIO_HEALTH_URL=${aws_lambda_function_url.visio_health_url.function_url}health"
}

# Testing outputs
output "curl_test_health" {
  description = "curl command to test health endpoint"
  value       = "curl ${aws_lambda_function_url.visio_health_url.function_url}health"
}

output "curl_test_status" {
  description = "curl command to test status endpoint"
  value       = "curl ${aws_lambda_function_url.visio_health_url.function_url}status"
}

# Monitoring
output "cloudwatch_logs_command" {
  description = "AWS CLI command to view logs"
  value       = "aws logs tail ${aws_cloudwatch_log_group.lambda_logs.name} --follow"
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.lambda_logs.name, "/", "$252F")}"
}

# Alternative: API Gateway outputs (if using API Gateway instead of Function URL)
/*
output "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_deployment.api_deployment.invoke_url
}

output "api_gateway_health_endpoint" {
  description = "API Gateway health check endpoint"
  value       = "${aws_api_gateway_deployment.api_deployment.invoke_url}/health"
}
*/
