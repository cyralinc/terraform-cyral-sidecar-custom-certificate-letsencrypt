resource "aws_cloudwatch_event_rule" "renewal_event" {
  name                = "CyralSidecarCertificateCASignedEventsRule-${random_id.current.id}"
  description         = "Triggers the Cyral Sidecar Certificate CA-Signed Lambda function as specified by the scheduled expression."
  is_enabled          = true
  schedule_expression = "cron(0 0 */${var.renewal_interval_days} * ? *)"
}

resource "aws_cloudwatch_event_target" "renewal_event_target" {
  target_id = "EVENTS"
  rule      = aws_cloudwatch_event_rule.renewal_event.name
  arn       = aws_lambda_function.lambda_function.arn
}
