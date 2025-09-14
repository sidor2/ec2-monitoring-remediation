data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = file("${path.module}/lambda_function.py")
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "remediate" {
  function_name = "${var.proj_name}-auto-response"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.handler"
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL          = "INFO"
      ISOLATION_SG       = aws_security_group.isolation_sg.id
      ISOLATION_RT       = aws_route_table.isolation.id
      INVEST_PROFILE_ARN = aws_iam_instance_profile.invest_profile.arn
    }
  }
}

# Allow CloudWatch Alarms to invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediate.function_name
  principal     = "events.amazonaws.com"  # CloudWatch uses this principal for alarms
  source_arn    = aws_cloudwatch_metric_alarm.cpu_high.arn  # Restrict to this alarm
}

# Allow EventBridge (GuardDuty) to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remediate.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_rule.arn
}