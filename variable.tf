variable "aws_region" {
  type    = string
}

variable "vpc_name" {
  type    = string
  default = "demo_vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "environment" {
  description = "The name of the environment"
  type        = string
  default     = "Dev"

}

variable "private_subnets" {
  default = {
    "private_subnet_1" = 1
    "private_subnet_2" = 2
    "private_subnet_3" = 3
  }
}

variable "public_subnets" {
  default = {
    "public_subnet_1" = 1
    "public_subnet_2" = 2
    "public_subnet_3" = 3
  }
}

variable "variables_sub_cidr" {
  description = "CIDR Block for the Variables Subnet"
  type        = string
  default     = "10.0.250.0/24"
}

variable "variables_sub_az" {
  description = "Availability Zone used Variables Subnet"
  type        = string
  default     = "ap-southeast-2a"
}

variable "variables_sub_auto_ip" {
  description = "Set Automatic IP Assignment for Variables Subnet"
  type        = bool
  default     = true
}

locals {
  service_name = "Automation"
  app_team     = "Cloud Team"
  createdby    = "terraform"
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Name      = lower(local.server_name)
    Owner     = lower(local.team)
    App       = lower(local.application)
    Service   = lower(local.service_name)
    AppTeam   = lower(local.app_team)
    CreatedBy = lower(local.createdby)
  }
}

variable "ap-southeast-2" {
  type = list(string)
  default = [
    "ap-southeast-2a",
    "ap-southeast-2b",
    "ap-southeast-2c"
  ]
}

variable "ip" {
  type = map(string)
  default = {
    Prod = "10.0.150.0/24"
    Dev  = "10.0.250.0/24"
  }

}

variable "env" {
  type = map(any)
  default = {
    Prod = {
      ip = "10.0.150.0/24"
      az = "ap-southeast-2a"
    }
    Dev = {
      ip = "10.0.250.0/24"
      az = "ap-southeast-2b"
    }
  }
}

variable "num_1" {
  type        = number
  description = "Numbers for function labs"
  default     = 88
}

variable "num_2" {
  type        = number
  description = "Numbers for function labs"
  default     = 73
}

variable "num_3" {
  type        = number
  description = "Numbers for function labs"
  default     = 52
}

variable "web_ingress" {
  type = map(object(
    {
      description = string
      port        = number
      protocol    = string
      cidr_block  = list(string)
    }
  ))
  default = {
    "80" = {
      description = "Port 80"
      port        = 80
      protocol    = "tcp"
      cidr_block  = ["0.0.0.0/0"]
    }
    "443" = {
      description = "Port 443"
      port        = 443
      protocol    = "tcp"
      cidr_block  = ["0.0.0.0/0"]
    }
  }
}
