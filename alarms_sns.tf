resource "aws_sns_topic" "alarms" {
  name = "${var.proj_name}-alarms-topic"

  tags = {
    Name = "${var.proj_name}-alarms-topic"
  }
}