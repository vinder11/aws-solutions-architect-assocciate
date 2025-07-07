# module "vpc_flow_logs_produccion" {
#   source = "../../modules/vpc_flow_logs"

#   vpc_id                   = module.vpc.vpc_id
#   log_destination_type     = "cloud-watch-logs"                                      # Puede ser "cloud-watch-logs" o "s3"
#   traffic_type             = "ALL"                                                   # Puede ser "ACCEPT", "REJECT"
#   max_aggregation_interval = 600                                                     # Intervalo máximo de agregación en segundos
#   log_group_name           = "${var.project_name}-${var.environment_name}-flow-logs" # Nombre del grupo de logs
#   log_group_retention_days = 30                                                      # Días de retención para los logs

#   tags = var.vpc_custom_tags
# }
