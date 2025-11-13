resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
  }
}

resource "aws_s3_bucket" "guardduty_ipsets" {
  bucket        = "cloudops-guardduty-ipsets-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_object" "trusted_ips" {
  bucket  = aws_s3_bucket.guardduty_ipsets.bucket
  key     = "trusted-ips.txt"
  content = "10.0.0.0/8\n172.16.0.0/12\n192.168.0.0/16"
}

resource "aws_guardduty_ipset" "trusted_ips" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/${aws_s3_bucket.guardduty_ipsets.bucket}/trusted-ips.txt"
  name        = "trusted-ips"

  depends_on = [aws_s3_object.trusted_ips]
}

resource "aws_sns_topic" "guardduty_alerts" {
  name = "guardduty-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-high-severity"
  description = "Capture high severity GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{
        numeric = [">", 7.0]
      }]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn
}

resource "aws_sns_topic_policy" "guardduty_alerts" {
  arn = aws_sns_topic.guardduty_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.guardduty_alerts.arn
    }]
  })
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
