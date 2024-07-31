output "external_id" {
  value = snowflake_api_integration.api_integration.api_aws_external_id
}

output "iam_user_arn" {
  value = snowflake_api_integration.api_integration.api_aws_iam_user_arn
}