# HCP Terraform Cloud Configuration
# Este projeto roda exclusivamente no HCP Terraform Cloud

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }

  cloud {
    organization = "SevenCl0ud"
    
    workspaces {
      # Workspace específico para o projeto BIA
      name = "SevenCloud_Challange"
    }
  }
}

# Provider AWS será configurado via variáveis de ambiente no HCP Terraform:
# - AWS_ACCESS_KEY_ID (sensitive)
# - AWS_SECRET_ACCESS_KEY (sensitive) 
# - AWS_DEFAULT_REGION (us-east-1)
provider "aws" {
  region = var.aws_region
}

# Provider adicional para backup cross-region (apenas produção)
provider "aws" {
  alias  = "backup_region"
  region = "us-west-2"
}