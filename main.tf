locals {
  # Define the exact zones you want to target
  target_zones = ["us-east-1a", "us-east-1b"]
}

# Create a VPC 
resource "aws_vpc" "compute_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "pub_subnet" {
  count = length(local.target_zones)
  vpc_id = aws_vpc.compute_vpc.id
  cidr_block = "10.0.${count.index}.0/24"
}

resource "aws_subnet" "priv_subnet" {
  count = length(local.target_zones)
  vpc_id = aws_vpc.compute_vpc.id
  cidr_block = "10.1.${count.index + 10}.0/24"
}

resource "aws_internet_gateway" "compute_igw" {
  vpc_id = aws_vpc.compute_vpc.id
}

## --- Security Group Block

resource "aws_security_group" "compute_lb_sg" {
  name = "allow_ingress_http"
  description = "Allow HTTP from all ingress"
  vpc_id = aws_vpc.compute_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "lb_ingress_rule" {
  security_group_id = aws_security_group.compute_lb_sg.id

  cidr_ipv4 = "0.0.0.0/0"
  from_port = "80"
  ip_protocol = "tcp"
  to_port = "80"
}

resource "aws_security_group" "compute_egress" {
  name = "allow_egress_all"
  description = "Allow all Egress traffic"
  vpc_id = aws_vpc.compute_vpc.id
}

resource "aws_vpc_security_group_egress_rule" "egress_rule" {
  security_group_id = aws_security_group.compute_ec2_sg.id

  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "tcp"
}

resource "aws_security_group" "compute_ec2_sg" {
  name = "allow_from_lb"
  description = "Allow all traffic that comes from the LB"
  vpc_id = aws_vpc.compute_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_lb_to_ec2" {
  security_group_id = aws_security_group.compute_ec2_sg.id

  # This ties the LB to the EC2 instances, so that the traffic is allows if it comes from the LBs SG (pretty sure)
  referenced_security_group_id = aws_security_group.compute_lb_sg
  ip_protocol = "tcp"
  from_port = "80"
  to_port = "80"
}

resource "aws_security_group" "restrict_ingress_traffic" {
  name = "block_internet_ingress"
  description = "Block all remaining ingress traffic"
  vpc_id = aws_vpc.compute_vpc.id
}

## -- Load Balacing & Compute Block

resource "aws_lb" "compute_lb" {
  name = "compute-lb"
  load_balancer_type = "application"
  security_groups = [aws_security_group.compute_lb_sg.id]
  subnets = [for subnet in aws_subnet.pub_subnet : subnet.id] # does this work? 
  # targets? 
}

resource "aws_launch_template" "compute_launch_template" {
  name = "compute-lt"
  instance_type = "t2.mirco"
  image_id = ""
  user_data = filebase64(${path.module}/userdata.sh)

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.compute_ec2_sg.id]
  }
  
  placement {
    availability_zone = length(local.target_zones)
  }
}

