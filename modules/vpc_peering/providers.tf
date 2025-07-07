# providers.tf

provider "aws" {
  alias  = "requester"
  region = "us-east-1"
  # Credenciales para la cuenta A (Requester)
}

provider "aws" {
  alias  = "accepter"
  region = "us-east-1"
  # Credenciales para la cuenta B (Accepter)
  # Puedes usar assume_role para esto
  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT_B_ID:role/TerraformPeeringRole"
  # }
}
