terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.33.0"
    }
  }
}

provider "aws" {
    region = "us-east-2"
}

variable "cidr_blocks_staging" {
  description = "CIDR blocks for the dev environment"
  type = list(object(
    {cidr_block = string,
    name = string}
  ))
}


resource "aws_vpc" "staging_vpc" {
    cidr_block = var.cidr_blocks_staging[0].cidr_block
    tags = {
      Name: var.cidr_blocks_staging[0].name
      vpc_env: var.cidr_blocks_staging[0].name
    }
  
}


resource "aws_subnet" "staging_subnet01" {
    vpc_id = aws_vpc.staging_vpc.id
    cidr_block = var.cidr_blocks_staging[1].cidr_block
    availability_zone = "us-east-2a"
    tags = {
      Name: var.cidr_blocks_staging[1].name
}
}

data "aws_vpc" "existing_vpc" {
    default = true
}

resource "aws_subnet" "staging_subnet02" {
    cidr_block = var.cidr_blocks_staging[2].cidr_block
    vpc_id = aws_vpc.staging_vpc.id
    availability_zone = "us-east-2a"
    tags = {
      Name: var.cidr_blocks_staging[2].name
    }
  
}


output "staging_vpc_id" {
    value = aws_vpc.staging_vpc.id
}

output "staging_subnet_id01" {
    value = aws_subnet.staging_subnet01.id
}


output "staging_subnet_id02" {
    value = aws_subnet.staging_subnet02.id
}