# Designate a cloud provider and region
# for security reason credentials are handled locally in a config file


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

data "aws_vpcs" "udacity" {
  tags = {
    Name = "Udacity_VPC_Primary"
  }
}

# provision 4 AWS t2.micro EC2 instances named Udacity T2

resource "aws_instance" "T2" {
  count         =  4
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  subnet_id     = "subnet-007ad38be3e0f33e0"

  tags = {
    Name  = "Udacity T2-${count.index + 1}"
  }
}

# provision 2 m4.large EC2 instances named Udacity M4

resource "aws_instance" "M4" {
  count         =  2
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "m4.large"
  subnet_id     = "subnet-007ad38be3e0f33e0"

  tags = {
    Name  = "Udacity M4-${count.index + 1}"
  }
}

# print vpc ID to make sure we are in the right area

output "udacity" {
  value = data.aws_vpcs.udacity.ids
}

