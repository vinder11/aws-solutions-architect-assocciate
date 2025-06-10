module "endpoint" {
  source                 = "../../modules/endpoints"
  vpc_id                 = module.vpc.vpc_id
  default_security_group = false # Permite el uso del grupo de seguridad por defecto
  endpoints = [
    {
      name              = "${var.project_name}-s3-endpoint-${var.environment_name}"
      service_name      = var.ep_service_name
      vpc_endpoint_type = var.ep_vpc_endpoint_type                    # Puede ser "Interface" o "Gateway"
      route_table_ids   = [module.private_route_table.route_table_id] # Asocia a las tablas de ruta privadas
      tags = merge(
        {
          Name = "${var.project_name}-${var.environment_name}-s3-endpoint"
        }
      )
    }
  ]
  tags = var.vpc_custom_tags # Incorpora etiquetas personalizadas del entorno

}
