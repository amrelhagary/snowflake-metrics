########## AWS ############
environment                   = "dev"
aws_region                    = "us-east-1"
api_name                      = "SnowflakeAPILambdaTerraform"
snowflake_aws_api_integration = "AWS_SNOWFLAKE_INTEGRATION_DEMO"
####### Snowflake ########
snowflake_role               = "SYSADMIN"
snowflake_region             = "us-west-2"
snowflake_database           = "SNOW_OPS"
snowflake_warehouse          = "DEMO_WH"
snowflake_schema             = "METRICS"
total_elapsed_time_threshold = 36000 #Milliseconds
