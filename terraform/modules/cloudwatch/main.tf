# ==============================================================================
# CloudWatch Module: Observability, Metric Alarms & Dashboard
# ==============================================================================

# ── 1. CloudWatch Log Group for ECS & Deployment Auditing ─────────────────────
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days

  tags = merge(
    var.tags,
    {
      Name        = var.log_group_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# ── 2. Metric Alarm: ECS High CPU Utilization ─────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm triggers when ECS CPU utilization exceeds 80% for 4 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  tags = var.tags
}

# ── 3. Metric Alarm: ALB Target 5XX Error Rate ────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm triggers when 5XX errors from ECS target group exceed 5 in 5 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = var.alb_target_group_arn_suffix
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.tags
}

# ── 4. CloudWatch Operational Dashboard ───────────────────────────────────────
resource "aws_cloudwatch_dashboard" "platform_health" {
  dashboard_name = "${var.project_name}-health-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name, { "color" = "#e65100", "label" = "ECS CPU Utilization (%)" }],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name, { "color" = "#0284c7", "label" = "ECS Memory Utilization (%)" }]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Fargate Compute Resources (CPU & Memory)"
          yAxis  = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { "stat" = "Sum", "color" = "#10b981", "label" = "ALB Total Requests" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { "stat" = "Average", "color" = "#8b5cf6", "label" = "Target Latency (s)" }]
          ]
          period = 60
          region = var.aws_region
          title  = "ALB Traffic & Response Latency"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { "stat" = "Sum", "color" = "#dc2626", "label" = "Target 5XX Errors" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", var.alb_arn_suffix, { "stat" = "Sum", "color" = "#f59e0b", "label" = "Target 4XX Errors" }]
          ]
          period = 60
          region = var.aws_region
          title  = "Application HTTP Error Codes (4XX / 5XX)"
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          query   = "SOURCE '${var.log_group_name}' | fields @timestamp, @message | sort @timestamp desc | limit 25"
          region  = var.aws_region
          title   = "Live Application & Deployment Logs"
          stacked = false
        }
      }
    ]
  })
}
