resource "aws_cloudwatch_metric_alarm" "mem_high" {
  alarm_name          = "EC2CPUHigh"
  alarm_description   = "CPU usage > 50% on instance"
  namespace           = "CustomEC2Metrics"
  metric_name         = "cpu_usage_user"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  threshold           = 50
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  dimensions = {
    hostname = aws_instance.app.host_id
  }
}
