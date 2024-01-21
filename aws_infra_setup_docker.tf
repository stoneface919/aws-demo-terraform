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

variable "cidr_blocks_aws" {
    description = "CIDR block for demo insfrastructure"
    type = list(object({
        cidr_block = string,
        name = string
    }))
}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "key_pub" {}

# CREATE VPC
resource "aws_vpc" "app01_vpc" {
    cidr_block = var.cidr_blocks_aws[0].cidr_block
    tags = {
      Name: "${var.env_prefix}-${var.cidr_blocks_aws[0].name}"
    } 
}

# CREATE ONE SUBNET IN ONE SINGLE AZ
resource "aws_subnet" "app01-subnet" {
    vpc_id = aws_vpc.app01_vpc.id
    tags = {
      Name: "${var.env_prefix}-${var.cidr_blocks_aws[1].name}"
    }
    cidr_block = var.cidr_blocks_aws[1].cidr_block
    availability_zone = "us-east-2a"
}

# CREATE A ROUTE TABLE INSIDE THE SUBNET AND LINK IT TO AN INTERNET GATEWAY
# VIRTUAL ROUTER 
resource "aws_route_table" "app01-route_table" {
    vpc_id = aws_vpc.app01_vpc.id
    route {
        # IG
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.app01-internet_gateway.id

    }
    tags = {
      Name: "${var.env_prefix}-rtb"
    }

}

# CREATING IG
# VIRTUAL WAN CONNECTION - MODEM
resource "aws_internet_gateway" "app01-internet_gateway" {
    vpc_id = aws_vpc.app01_vpc.id
    tags = {
      Name: "${var.env_prefix}-igw"
    }
}

# ASSOCIATION OF RTB ANMD SUBNET
resource "aws_route_table_association" "app01-rtb-subnet" {
    subnet_id = aws_subnet.app01-subnet.id
    route_table_id = aws_route_table.app01-route_table.id
}

# CREATE A SECURITY GROUP - CONFIGURE INBOUND/OUTBOUND RULES
resource "aws_security_group" "app01-sg" {
    name = "app01-sg"
    description = "Allow SSH and NGNIX inbound traffic"
    vpc_id = aws_vpc.app01_vpc.id
    # ssh alloww
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    # allow proxy traffic
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []

    }
    tags = {
      Name: "${var.env_prefix}-app01-sg"
    }
}

# FETCH AMI -> EC2 INSTANCE
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
      name = "name"
      values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }

}

# CREATE EC2 INTANCE AND ASSOCIATE WITH SECURITY GROUP/VPC
resource "aws_instance" "app01-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.app01-sg.id]
    # security_groups = [aws_security_group.app01-sg.id]
    subnet_id = aws_subnet.app01-subnet.id
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    key_name = aws_key_pair.app01-keypair.key_name
    user_data_base64 = "IyFiaW4vYmFzaAp5dW0gdXBkYXRlIC15ICYmIHl1bSBpbnN0YWxsIC15IGRvY2tlcgpzeXN0ZW1jdGwgc3RhcnQgZG9ja2VyCnVzZXJtb2QgLWFHIGRvY2tlciBlYzItdXNlcgpkb2NrZXIgcnVuIC1wIDgwODA6ODAgbmdpbng="

}


# CREATE KEY PAIR
resource "aws_key_pair" "app01-keypair" {
  key_name = "app01-server-key"
  public_key = var.key_pub
}


# output "amazon-linux-latest" {
#     value = data.aws_ami.latest-amazon-linux-image
  
# }

# DEPLOY EC2 INSTANCE WITH A DOCKER CONTAINER

