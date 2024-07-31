variable "api_aws_role_arn" {
  description = "AWS role arn"
  type        = string
}

variable "api_allowed_prefixes" {
  description = "API allowed prefixes"
  type        = string
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

variable "snowflake_schema" {
  description = "snowflake schema"
  type        = string
}

variable "snowflake_aws_api_integration" {
  type    = string
  default = "AWS_INTEGRATION"
}

variable "external_function_name" {
  description = "snowflake external function name"
  type        = string
  default     = "SEND_CLOUDWATCH_METRICS"
}

variable "query_history_detail_view" {
  description = "Query history detail"
  type        = string
  default     = "VW_ACS_QUERY_HSTR_DTL"
}

variable "long_running_queries_procedure" {
  description = "Snowflake Procedure"
  type        = string
  default     = "CLOUDWATCH_LONG_RUN_QUERIES"
}

variable "cloudwatch_snowflake_task" {
  description = "cloudwatch snowflake task for calling the procedure"
  type        = string
  default     = "cloudwatch_snowflake_task"
}

variable "snowflake_cloudwatch_task_schedule" {
  description = "snowflake cloudwatch task schedule"
  type        = string
  default     = "2 MINUTE"
}

variable "total_elapsed_time_threshold" {
  type = string
}
