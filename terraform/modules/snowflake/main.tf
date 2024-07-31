terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.56.0"
    }
  }
}

provider "snowflake" {
  region = var.snowflake_region
  role   = var.snowflake_role
  # warehouse = var.snowflake_warehouse
}

resource "snowflake_database" "db" {
  name    = var.snowflake_database
  comment = "This is OPS Database"
}

resource "snowflake_warehouse" "warehouse" {
  name           = var.snowflake_warehouse
  warehouse_size = "x-small"

  auto_suspend = 60
}

resource "snowflake_schema" "schema" {
  database = snowflake_database.db.name
  name     = var.snowflake_schema
  comment  = "This is OPS schema"
}

resource "snowflake_database_grant" "grant" {
  database_name = snowflake_database.db.name

  privilege = "USAGE"
  roles     = ["SYSADMIN"]

  with_grant_option = true
}


resource "snowflake_schema_grant" "grant" {
  database_name = snowflake_database.db.name
  schema_name   = snowflake_schema.schema.name

  privilege = "OWNERSHIP"
  roles     = ["SYSADMIN"]

  with_grant_option = true
}

resource "snowflake_api_integration" "api_integration" {
  name                 = var.snowflake_aws_api_integration
  api_provider         = "aws_api_gateway"
  api_aws_role_arn     = var.api_aws_role_arn
  api_allowed_prefixes = [var.api_allowed_prefixes]
  enabled              = true
}

resource "snowflake_integration_grant" "grant" {
  integration_name = snowflake_api_integration.api_integration.name

  privilege = "USAGE"
  roles     = ["SYSADMIN"]

  with_grant_option = true
}


resource "snowflake_function_grant" "grant" {
  database_name       = snowflake_database.db.name
  schema_name         = snowflake_schema.schema.name
  function_name       = snowflake_external_function.send_cloudwatch_metric.name
  argument_data_types = ["string", "number", "string", "string", "varchar"]
  privilege           = "USAGE"
  roles               = ["SYSADMIN"]
  on_future           = false
  with_grant_option   = false
}

resource "snowflake_procedure_grant" "grant" {
  database_name     = snowflake_database.db.name
  schema_name       = snowflake_schema.schema.name
  procedure_name    = snowflake_procedure.long_running_queries_procedure.name
  privilege         = "USAGE"
  roles             = ["SYSADMIN"]
  on_future         = false
  with_grant_option = false
}

resource "snowflake_external_function" "send_cloudwatch_metric" {
  name     = local.external_function_name
  database = snowflake_database.db.name
  schema   = snowflake_schema.schema.name
  arg {
    name = "METRICNAME"
    type = "string"
  }
  arg {
    name = "VALUE"
    type = "number"
  }
  arg {
    name = "UNIT"
    type = "string"
  }
  arg {
    name = "NAMESPACE"
    type = "string"
  }
  arg {
    name = "DIMENSION_JSON"
    type = "varchar"
  }
  return_type               = "variant"
  return_behavior           = "IMMUTABLE"
  api_integration           = snowflake_api_integration.api_integration.name
  url_of_proxy_and_resource = var.api_allowed_prefixes
}

resource "snowflake_view" "query_history_detil_view" {
  name     = var.query_history_detail_view
  database = snowflake_database.db.name
  schema   = snowflake_schema.schema.name

  comment = "Query history detail"

  statement  = <<-SQL
SELECT 
    QUERY_TEXT, 
    DATABASE_NAME, 
    SCHEMA_NAME, 
    QUERY_TYPE, 
    USER_NAME, 
    ROLE_NAME, 
    EXECUTION_STATUS, 
    START_TIME, 
    cast(START_TIME as date) as start_date,
    END_TIME,
    cast(END_TIME as date) as end_date,
    TOTAL_ELAPSED_TIME, 
    BYTES_SCANNED, 
    ROWS_PRODUCED, 
    SESSION_ID, 
    QUERY_ID, 
    QUERY_TAG, 
    WAREHOUSE_NAME, 
  COMPILATION_TIME,
  execution_time,
  queued_provisioning_time 
  FROM snowflake.account_usage.query_history 
WHERE 
QUERY_TYPE NOT IN ('DESCRIBE', 'SHOW');
SQL
  or_replace = true
  is_secure  = false
}

resource "snowflake_procedure" "long_running_queries_procedure" {
  name                = var.long_running_queries_procedure
  database            = snowflake_database.db.name
  schema              = snowflake_schema.schema.name
  language            = "JAVASCRIPT"
  comment             = "Query snowflake metrics and send metric to snowflake external function for long running queries"
  return_type         = "STRING"
  execute_as          = "CALLER"
  null_input_behavior = "RETURNS NULL ON NULL INPUT"
  statement           = <<EOT
        result = '';
                    
        try {
            // change total_elapsed_time >=  3600000 in production
            var smt_get_top_failed_queries = `select current_account(),avg(total_elapsed_time) from ${snowflake_view.query_history_detil_view.name} 
where total_elapsed_time >= 36000 group by current_account()`;
            
            var top_failed_queries = snowflake.execute( {sqlText: smt_get_top_failed_queries} );

            while (top_failed_queries.next()) {
                account_id_val = top_failed_queries.getColumnValue(1);
                total_elapsed_time_val = top_failed_queries.getColumnValue(2);

                var smt_update_cloud_watch = 
                    `SELECT ${snowflake_external_function.send_cloudwatch_metric.name}(
                     \'Total_Elapsed_Time\',` +
                     total_elapsed_time_val + `,
                     \'Milliseconds\',
                     \'Snowflake\',
                     \'[{\\"Name\\": \\"Account\\",\\"Value\\": \\"`+account_id_val+`\\"}]\'
                    )`;

                snowflake.execute( {sqlText: smt_update_cloud_watch} );

                result = 'Success';              
            }
        }
        catch (err) {
            result =  "Failed: Code: " + err.code + "\n  State: " + err.state;
            result += "\n  Message: " + err.message;
            result += "\nStack Trace:\n" + err.stackTraceTxt;
        }
          
        return result; 
EOT
}


resource "snowflake_task" "send_metrics_to_cloudwatch_tasks" {
  comment = "task for calling snowflake procedure"

  database  = snowflake_database.db.name
  schema    = snowflake_schema.schema.name
  warehouse = var.snowflake_warehouse

  name          = var.cloudwatch_snowflake_task
  schedule      = var.snowflake_cloudwatch_task_schedule
  sql_statement = "CALL ${var.long_running_queries_procedure}()"


  enabled = true
}


resource "snowflake_task_grant" "grant" {
  database_name = snowflake_database.db.name
  schema_name   = snowflake_schema.schema.name
  task_name     = snowflake_task.send_metrics_to_cloudwatch_tasks.name

  privilege = "OPERATE"
  roles     = ["SYSADMIN"]

  on_future         = false
  with_grant_option = true
}
