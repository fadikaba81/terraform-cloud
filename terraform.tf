terraform {
   backend "remote" {
    hostname     = "app.terraform.io"
    organization = "fkaba-terraform-hc-exam"
    workspaces {
      name = "devops-aws-myapp-dev"
    }
  }

# backend "local" {
#     path="terraform.tfstate"
  
# }


  required_version = "~>1.9.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.12.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}