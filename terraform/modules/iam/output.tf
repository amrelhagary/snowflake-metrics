output "snowflake_cloudwatch_role_name" {
  value = aws_iam_role.iam_role_trust_entities.name
}

output "aws_iam_role_arn" {
  value = aws_iam_role.iam_role_trust_entities.arn
}