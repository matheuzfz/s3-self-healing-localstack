terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Versão estável para uso do LocalStack
    }
  }
}

provider "aws" {
  region                      = "sa-east-1"
  access_key                  = "test" # Credenciais falsas para uso do locastack
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  s3_use_path_style = true # Configuração para S3 no LocalStack

  # Redirecionamento de endpoints para o LocalStack
  endpoints {
    s3             = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    iam            = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    cloudwatchlogs = "http://localhost:4566"
  }
}