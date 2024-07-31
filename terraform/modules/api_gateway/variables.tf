variable "api_name" {
  description = "API Gateway name"
  type        = string
  default     = "SnowflakeLambdaProxyTerraform"
}

variable "lambda_arn" {
  description = "Snowflake Lambda proxy arn"
  type        = string
}

variable "lambda_function_name" {
  description = "lambda function name"
  type        = string
}

variable "api_gateway" {
  description = "Snowflake Lambda Proxy"
  type        = string
  default     = "SnowflakeLambdaProxy"
}

variable "stage_name" {
  description = "API deployment satge name"
  type        = string
  default     = "dev"
}

variable "account_no" {
  description = "AWS Account No"
  type        = string
}

variable "snowflake_cloudwatch_role_name" {
  description = "Snowflake Cloudwatch role name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}
