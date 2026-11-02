resource "aws_sns_topic" "audit" {
  name = "${var.project_name}-audit"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.audit.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# RDS instance events (failover, reboot, maintenance) feed the audit Lambda.
resource "aws_cloudwatch_event_rule" "rds_events" {
  name        = "${var.project_name}-rds-events"
  description = "RDS DB instance events for the lab database"

  event_pattern = jsonencode({
    source        = ["aws.rds"]
    "detail-type" = ["RDS DB Instance Event"]
    detail = {
      SourceIdentifier = [module.rds.db_instance_identifier]
    }
  })
}

resource "aws_cloudwatch_event_target" "rds_events_audit" {
  rule = aws_cloudwatch_event_rule.rds_events.name
  arn  = aws_lambda_function.audit.arn
}

resource "aws_lambda_permission" "eventbridge_audit" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.audit.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rds_events.arn
}
