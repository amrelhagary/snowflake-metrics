# IAM role for snowflake external function intergration
resource "aws_iam_role" "iam_role_trust_entities" {
  name = var.snowflake_cloudwatch_iam

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "automation.amazonaws.com"
        }
      },
    ]
  })
}
