variable "snowflake_cloudwatch_iam" {
  type    = string
  default = "SnowflakeCloudwatchMetricsAccessRole"
}

variable "account_no" {
  description = "AWS account No"
  type        = string
}
