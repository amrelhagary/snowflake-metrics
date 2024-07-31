variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS profile"
  type        = string
}

variable "account_no" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

# variable "snowflake_account_no" {
#   type = string
# }

variable "snowflake_schema" {
  type = string
}

variable "snowflake_role" {
  description = "snowflake role"
  type        = string
}

variable "snowflake_region" {
  description = "snowflake region"
  type        = string
}

variable "snowflake_database" {
  description = "snowflake database"
  type        = string
}

variable "snowflake_warehouse" {
  description = "snowflake warehouse"
  type        = string
}

variable "total_elapsed_time_threshold" {
  type = string
}

variable "api_name" {
  type = string
}

variable "snowflake_aws_api_integration" {
  type = string
}
