# Configure the AWS Provider
/*Iac Build a infra for terraform exam
Description; AWS Infra buildout
*/

#Configuration provider 
provider "aws" {
   region = var.aws_region

  default_tags {
    tags = {
      Environment = terraform.workspace
      Owner       = "Acme"
      Provisoned  = "Terraform"
    }
  }
}

#Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

locals {
  team        = "api_mgmt_dev"
  application = "core_api"
  server_name = "ec2-${var.environment}-api-${var.variables_sub_az}"
}


#Define the VPC 
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = upper(var.vpc_name)
    Environment = upper(var.environment)
    Terraform   = "true"
    Region      = data.aws_region.current.description

  }
}

resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Demo IGW"
  }

}

resource "aws_route" "demo_route_table" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demo_igw.id

}

#Deploy the private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value % length(data.aws_availability_zones.available.names)]
  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#Deploy the public subnets
resource "aws_subnet" "public_subnets" {
  for_each          = var.public_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value % length(data.aws_availability_zones.available.names)]

  map_public_ip_on_launch = true

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

data "aws_s3_bucket" "data_bucket" {
  bucket = "my-data-lookup-fk"
}

resource "aws_iam_policy" "policy" {
  name        = "data_bucket_policy"
  description = "Allow access to my bucket"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" : "${data.aws_s3_bucket.data_bucket.arn}"
      }
    ]
  })
}

# Terraform Data Block - To Lookup Latest Ubuntu 20.04 AMI Image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_s3_bucket" "my-aws-s3-bucket" {
  bucket = "fkaba-sirri-${random_id.randomness.hex}"

  tags = {
    Name    = "MY s3 bucket"
    Purpose = "Building an automation"
  }

}

# Terraform Resource Block - To Build EC2 instance in Public Subnet
resource "aws_instance" "ubuntu_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups = [aws_security_group.vpc-ping.id,
  aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }

  # provisioner "local-exec" {
  #   command = "chmod 600 ${local_file.private_key_pem.filename}"

  # }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp ",
      "sudo sh  /tmp/assets/setup-web.sh",
    ]
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [security_groups]
  }
}

resource "aws_subnet" "variables-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.variables_sub_cidr
  availability_zone       = var.variables_sub_az
  map_public_ip_on_launch = var.variables_sub_auto_ip

  tags = {
    Name      = "sub-variable-${var.variables_sub_az}"
    Terraform = "true"
  }
}

resource "random_id" "randomness" {
  byte_length = 16
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

# resource "local_file" "private_key_pem" {
#   content  = tls_private_key.generated.private_key_pem
#   filename = "MyAWSKey.pem"
# }

resource "aws_key_pair" "generated" {
  key_name   = "MyAWSKey${var.environment}"
  public_key = tls_private_key.generated.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}

# Security Groups

resource "aws_security_group" "ingress-ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.vpc.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group - Web Traffic
resource "aws_security_group" "vpc-web" {
  name        = "vpc-web-${terraform.workspace}"
  vpc_id      = aws_vpc.vpc.id
  description = "Web Traffic"
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc-ping" {
  name        = "vpc-ping"
  vpc_id      = aws_vpc.vpc.id
  description = "ICMP for Ping Access"
  ingress {
    description = "Allow ICMP Traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "autoscaling" {
  source = "github.com/terraform-aws-modules/terraform-aws-autoscaling"

  # Autoscaling group
  name = "myasg"

  vpc_zone_identifier = [
    aws_subnet.private_subnets["private_subnet_1"].id,
    aws_subnet.private_subnets["private_subnet_2"].id,
    aws_subnet.private_subnets["private_subnet_3"].id
  ]
  min_size         = 0
  max_size         = 1
  desired_capacity = 1

  # Launch template
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  instance_name = "asg-instance"

  tags = {
    Name = "Web EC2 Server 2"
  }
}

# resource "aws_subnet" "list_subnet" {
#   for_each          = var.env
#   vpc_id            = aws_vpc.vpc.id
#   cidr_block        = each.value.ip
#   availability_zone = each.value.az

#   tags = {
#     "Environment" = each.key
#   }

# }

locals {
  maximum = max(var.num_1, var.num_2, var.num_3)
  minimum = min(var.num_1, var.num_2, var.num_3, 44, 20)
}

locals {
  ingress_rule = [{
    port        = 443
    description = "Https"
    },
    {
      port        = 80
      description = "HTTP"
  }]
}

resource "aws_security_group" "main" {
  name   = "core-sg-global"
  vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.web_ingress
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_block
    }
  }

  lifecycle {
    create_before_destroy = true
    # prevent_destroy = true
  }
}
