resource "aws_cloudwatch_metric_alarm" "mem_high" {
  alarm_name          = "EC2MemoryHigh"
  alarm_description   = "Memory usage > 85% on instance"
  namespace           = "Custom/EC2"
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 85
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    InstanceId = aws_instance.app.id
  }
}
