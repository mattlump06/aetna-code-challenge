locals {
  name_prefix = "${var.app_name}-${var.environment}"
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Name        = "${local.name_prefix}-alerts"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm for ECS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${local.name_prefix}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when ECS service CPU utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = {
    Name        = "${local.name_prefix}-ecs-cpu-alarm"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CloudWatch Alarm for Error Log Entries
resource "aws_cloudwatch_log_metric_filter" "error_logs" {
  name           = "${local.name_prefix}-error-logs"
  log_group_name = var.log_group_name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "ECS/${local.name_prefix}"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "error_logs" {
  alarm_name          = "${local.name_prefix}-error-logs-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = "ECS/${local.name_prefix}"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when more than 10 ERROR log entries are written in a minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = {
    Name        = "${local.name_prefix}-error-logs-alarm"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

