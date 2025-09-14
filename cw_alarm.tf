resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "EC2CPUHigh"
  alarm_description   = "CPU usage >85% on EC2 instance"  # Matches the console's "No description"
  namespace           = "CustomEC2Metrics"
  metric_name         = "cpu_usage_user"
  statistic           = "Average"
  period              = 60  
  evaluation_periods  = 3   
  threshold           = 85
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "missing"

  dimensions = {
    host = "${aws_instance.app.private_dns}"
    cpu  = "cpu-total"
    # Project = "${var.proj_name}-instance"
  }

  tags = {
    Name = "${var.proj_name}-CloudWatchAlarm"
  }
}