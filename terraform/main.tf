terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# AWS IAM role
module "iam" {
  source     = "./modules/iam"
  account_no = var.account_no
}

# Snowflake cloudwatch lambda
module "lambda" {
  source = "./modules/lambda"
}

# AWS API Gateway
module "api_gateway" {
  source                         = "./modules/api_gateway"
  api_name                       = var.api_name
  lambda_arn                     = module.lambda.arn
  lambda_function_name           = module.lambda.function_name
  account_no                     = var.account_no
  snowflake_cloudwatch_role_name = module.iam.snowflake_cloudwatch_role_name
  aws_region                     = var.aws_region

  depends_on = [
    module.lambda
  ]
}

module "snowflake" {
  source = "./modules/snowflake"

  snowflake_region              = var.snowflake_region
  snowflake_schema              = var.snowflake_schema
  snowflake_role                = var.snowflake_role
  snowflake_database            = var.snowflake_database
  snowflake_warehouse           = var.snowflake_warehouse
  api_aws_role_arn              = module.iam.aws_iam_role_arn
  api_allowed_prefixes          = module.api_gateway.base_url
  total_elapsed_time_threshold  = var.total_elapsed_time_threshold
  snowflake_aws_api_integration = var.snowflake_aws_api_integration
}

data "template_file" "snowflake_cloudwatch_role" {
  template = file("${path.module}/templates/snowflake-role.tpl")
  vars = {
    aws_external_id  = module.snowflake.external_id
    aws_iam_user_arn = module.snowflake.iam_user_arn
  }
}

resource "null_resource" "update_snowflake_role" {
  provisioner "local-exec" {
    command = <<-EOT
      aws iam update-assume-role-policy --role-name ${module.iam.snowflake_cloudwatch_role_name} --policy-document '${data.template_file.snowflake_cloudwatch_role.rendered}'
    EOT
  }
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [
    module.snowflake
  ]
}

output "aws_external_id" {
  value = module.snowflake.external_id
}
output "aws_iam_user_arn" {
  value = module.snowflake.iam_user_arn
}
output "api_allowed_prefixes" {
  value = module.api_gateway.base_url
}
