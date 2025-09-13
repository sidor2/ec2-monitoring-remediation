resource "aws_guardduty_detector" "gd" {
  enable = true
}

resource "aws_cloudwatch_event_rule" "guardduty_rule" {
  name        = "guardduty-to-lambda"
  description = "Route GuardDuty findings to remediation lambda"
  event_pattern = jsonencode({
    "source"      : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "gd_to_lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_rule.name
  target_id = "RemediateLambda"
  arn       = aws_lambda_function.remediate.arn
}
