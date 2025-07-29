# ==================================================
# EJEMPLOS DE USO
# ==================================================

module "ec2_role" {
  source = "../../modules/iam-role"

  role_name        = "ec2-s3-list-role"
  role_description = "Rol listar buckets S3 desde EC2"
  path             = "/${var.project_name}/"

  trusted_entities = {
    services = ["ec2.amazonaws.com"]
  }

  managed_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = var.vpc_custom_tags
}

/*
# Ejemplo 1: Rol para Lambda
module "lambda_role" {
  source = "./modules/aws-iam-role"
  
  role_name        = "lambda-execution-role"
  role_description = "Rol para ejecución de funciones Lambda"
  
  trusted_entities = {
    services = ["lambda.amazonaws.com"]
  }
  
  managed_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
  
  inline_policies = {
    "custom-s3-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = "arn:aws:s3:::my-bucket/*"
        }
      ]
    })
  }
  
  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}

# Ejemplo 2: Rol para cross-account access
module "cross_account_role" {
  source = "./modules/aws-iam-role"
  
  role_name        = "cross-account-role"
  role_description = "Rol para acceso entre cuentas"
  
  trusted_entities = {
    aws_accounts = ["123456789012", "987654321098"]
  }
  
  managed_policies = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
  
  max_session_duration = 7200
  
  tags = {
    Environment = "shared"
    Purpose     = "cross-account"
  }
}

# Ejemplo 3: Rol para EC2 con políticas múltiples
module "ec2_role" {
  source = "./modules/aws-iam-role"
  
  role_name        = "ec2-application-role"
  role_description = "Rol para instancias EC2 de aplicación"
  
  trusted_entities = {
    services = ["ec2.amazonaws.com"]
  }
  
  managed_policies = [
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  
  inline_policies = {
    "dynamodb-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
          ]
          Resource = "arn:aws:dynamodb:*:*:table/my-app-*"
        }
      ]
    })
    
    "secrets-access" = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = "arn:aws:secretsmanager:*:*:secret:my-app/*"
        }
      ]
    })
  }
  
  permissions_boundary = "arn:aws:iam::123456789012:policy/DeveloperBoundary"
  
  tags = {
    Environment = "development"
    Application = "my-app"
  }
}

# Ejemplo 4: Rol para GitHub Actions (OIDC)
module "github_actions_role" {
  source = "./modules/aws-iam-role"
  
  role_name        = "github-actions-role"
  role_description = "Rol para GitHub Actions CI/CD"
  
  trusted_entities = {
    federated = ["arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"]
  }
  
  # Política de asunción personalizada para OIDC con condiciones
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:my-org/my-repo:*"
          }
        }
      }
    ]
  })
  
  managed_policies = [
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]
  
  tags = {
    Environment = "ci-cd"
    Purpose     = "github-actions"
  }
}
*/
