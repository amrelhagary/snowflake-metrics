data "archive_file" "zip" {
  type        = "zip"
  source_file = local.lambda_source_filename
  output_path = local.lambda_zippped_filename
}


resource "aws_iam_role" "iam_for_lambda" {
  name               = var.snowflake_cloudwatch_iam
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  # Write logs to cloudwatch
  statement {
    sid    = "WriteCloudWatchLogs"
    effect = "Allow"
    resources = [
      "*"
    ]
    actions = [
      "cloudwatch:*",
    ]
  }
}

resource "aws_lambda_function" "lambda" {
  function_name    = local.aws_lambda_function
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "lambda_function.lambda_handler"
  package_type     = "Zip"
  architectures    = ["x86_64"]
  runtime          = "python3.8"
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${var.snowflake_cloudwatch_iam}-lambda-policy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_cloudwatch_log_group" "cloudwatch" {
  name = "/aws/lambda/${aws_lambda_function.lambda.function_name}"

  retention_in_days = 14
}
