# Proyecto de VPC con Terraform

Este proyecto implementa una Virtual Private Cloud (VPC) en AWS utilizando Terraform.
Está diseñado con un enfoque modular para facilitar la reutilización y la gestión de diferentes entornos.

## Estructura del Proyecto

- **`modules/vpc/`**: Contiene el módulo reutilizable de Terraform para crear la VPC.
  - `main.tf`: Define los recursos de AWS para la VPC.
  - `variables.tf`: Define las variables de entrada para el módulo VPC.
  - `outputs.tf`: Define los valores de salida del módulo VPC.
- **`environments/dev/`**: Contiene la configuración específica para el entorno de desarrollo.
  - `main.tf`: Configura el proveedor de AWS y llama al módulo VPC.
  - `variables.tf`: Define las variables específicas del entorno (ej. región).
  - `terraform.tfvars`: Proporciona los valores para las variables del entorno de desarrollo.

## Uso

1. **Requisitos Previos**:
    - [Terraform](https://www.terraform.io/downloads.html) instalado.
    - Credenciales de AWS configuradas (ej. mediante AWS CLI, variables de entorno, o roles IAM).

2. **Inicialización**:
    Navega al directorio del entorno que deseas desplegar (ej. `environments/dev/`) y ejecuta:

    ```bash
    terraform init
    ```

3. **Planificación**:
    Para ver los cambios que Terraform aplicará:

    ```bash
    terraform plan -var-file="terraform.tfvars"
    ```

4. **Aplicación**:
    Para desplegar la infraestructura:

    ```bash
    terraform apply -var-file="terraform.tfvars" -auto-approve
    ```

5. **Destrucción**:
    Para eliminar la infraestructura creada:

    ```bash
    terraform destroy -var-file="terraform.tfvars" -auto-approve
    ```

## Futuras Ampliaciones

Esta estructura base de VPC puede ser extendida para incluir:

- **Subredes Públicas y Privadas**: Creando un módulo de subredes que se pueda instanciar múltiples veces.
- **Internet Gateway (IGW)**: Para permitir el acceso a internet a recursos en subredes públicas.
- **NAT Gateway/Instance**: Para permitir a instancias en subredes privadas acceder a internet para actualizaciones, sin exponerlas directamente.
- **Tablas de Ruteo**: Personalizar el enrutamiento para subredes públicas y privadas.
- **Network ACLs y Security Groups**: Definir reglas de firewall a nivel de subred y de instancia.
- **VPC Endpoints**: Para acceder a servicios de AWS de forma privada.
- **VPC Peering**: Para conectar esta VPC con otras VPCs.
- **Módulos adicionales**: Para recursos como instancias EC2, bases de datos RDS, balanceadores de carga, etc.
