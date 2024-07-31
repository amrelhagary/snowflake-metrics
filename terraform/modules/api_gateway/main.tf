resource "aws_api_gateway_rest_api" "snowflake_lambda_proxy" {
  name = var.api_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_rest_api_policy" "policy" {
  rest_api_id = aws_api_gateway_rest_api.snowflake_lambda_proxy.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:sts::${var.account_no}:assumed-role/${var.snowflake_cloudwatch_role_name}/snowflake"
      },
      "Action": "execute-api:Invoke",
      "Resource": "${aws_api_gateway_rest_api.snowflake_lambda_proxy.execution_arn}/*/POST/"
    }
  ]
}
EOF
}


resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.snowflake_lambda_proxy.id
  resource_id   = aws_api_gateway_rest_api.snowflake_lambda_proxy.root_resource_id
  http_method   = "POST"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.snowflake_lambda_proxy.id
  resource_id             = aws_api_gateway_rest_api.snowflake_lambda_proxy.root_resource_id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_arn
}

resource "aws_api_gateway_method_response" "get_region_mappings_response_200" {
  rest_api_id = aws_api_gateway_rest_api.snowflake_lambda_proxy.id
  resource_id = aws_api_gateway_rest_api.snowflake_lambda_proxy.root_resource_id
  http_method = aws_api_gateway_method.method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "region-mappings-integration-get-response" {
  depends_on  = [aws_api_gateway_integration.api_integration]
  rest_api_id = aws_api_gateway_rest_api.snowflake_lambda_proxy.id
  resource_id = aws_api_gateway_rest_api.snowflake_lambda_proxy.root_resource_id
  http_method = aws_api_gateway_method.method.http_method
  status_code = aws_api_gateway_method_response.get_region_mappings_response_200.status_code
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.snowflake_lambda_proxy.execution_arn}/*/POST/"
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.snowflake_lambda_proxy.id
  stage_name  = var.stage_name
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.api_integration.id
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.api_integration,
    aws_api_gateway_rest_api_policy.policy,
    aws_api_gateway_integration_response.region-mappings-integration-get-response
  ]
}
resource "aws_api_gateway_stage" "rest_api_stage" {
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.snowflake_lambda_proxy.id
  stage_name    = var.stage_name
}

resource "aws_api_gateway_method_settings" "enable_logging" {
  rest_api_id = aws_api_gateway_rest_api.snowflake_lambda_proxy.id
  stage_name  = aws_api_gateway_stage.rest_api_stage.stage_name
  method_path = "*/*"

  settings {
    logging_level          = "INFO"
    metrics_enabled        = true
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}
