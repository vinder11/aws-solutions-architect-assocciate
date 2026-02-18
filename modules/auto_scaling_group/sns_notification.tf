# Crear tema SNS sólo si el usuario no ha traído el suyo
resource "aws_sns_topic" "this" {
  count = var.sns_topic_arn == null && var.create_autoscaling_notification ? 1 : 0

  name         = substr(var.sns_display_name, 0, 256)
  display_name = var.sns_display_name
}

# Crear suscripción sólo si hemos creado el tema
resource "aws_sns_topic_subscription" "this" {
  count = var.sns_topic_arn == null && var.sns_endpoint != "" && var.create_autoscaling_notification ? 1 : 0

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = var.sns_protocol
  endpoint  = var.sns_endpoint
}
