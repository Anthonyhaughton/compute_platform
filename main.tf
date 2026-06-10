locals {
  # Define the exact zones you want to target
  target_zones = ["us-east-1a", "us-east-1b"]
}

# Create a VPC 
resource "aws_vpc" "compute_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "pub_subnet" {
  count             = length(local.target_zones)
  vpc_id            = aws_vpc.compute_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = local.target_zones[count.index]
}

resource "aws_subnet" "priv_subnet" {
  count      = length(local.target_zones)
  vpc_id     = aws_vpc.compute_vpc.id
  cidr_block = "10.0.${count.index + 10}.0/24"
}

resource "aws_internet_gateway" "compute_igw" {
  vpc_id = aws_vpc.compute_vpc.id
}

resource "aws_route_table" "compute-public-rt" {
  vpc_id = aws_vpc.compute_vpc.id
}

resource "aws_route" "compute-public-route" {
  route_table_id         = aws_route_table.compute-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.compute_igw.id
}

resource "aws_route_table_association" "compute-rta" {
  count          = length(local.target_zones)
  subnet_id      = aws_subnet.pub_subnet[count.index].id
  route_table_id = aws_route_table.compute-public-rt.id
}

## -- ALB
resource "aws_security_group" "compute_lb_sg" {
  name        = "allow_ingress_http"
  description = "Allow HTTP from all ingress"
  vpc_id      = aws_vpc.compute_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "lb_ingress_rule" {
  security_group_id = aws_security_group.compute_lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lb_egress_rule" {
  security_group_id = aws_security_group.compute_lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Let the ALB talk to any backend target
}


## -- Compute
resource "aws_security_group" "compute_ec2_sg" {
  name        = "allow_from_lb"
  description = "Allow all traffic that comes from the LB"
  vpc_id      = aws_vpc.compute_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_lb_to_ec2" {
  security_group_id            = aws_security_group.compute_ec2_sg.id
  referenced_security_group_id = aws_security_group.compute_lb_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "compute_ec2_ssh_sg" {
  name        = "allow-ssh"
  description = "allow SSH"
  vpc_id      = aws_vpc.compute_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "compute-ssh" {
  security_group_id = aws_security_group.compute_ec2_ssh_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_vpc_security_group_egress_rule" "ec2_egress_rule" {
  security_group_id = aws_security_group.compute_ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Needed so EC2 can pull packages during bootstrap
}

## -- Load Balacing & Compute Block

resource "aws_lb" "compute_lb" {
  name               = "compute-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.compute_lb_sg.id]
  subnets            = [for subnet in aws_subnet.pub_subnet : subnet.id]
}

resource "aws_lb_target_group" "compute-tg" {
  name     = "compute-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.compute_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "compute_listener" {
  load_balancer_arn = aws_lb.compute_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.compute-tg.arn
  }
}

resource "aws_launch_template" "compute_launch_template" {
  name          = "compute-lt"
  instance_type = "t2.micro"
  image_id      = "ami-0152204c1a187337c"
  user_data     = filebase64("${path.module}/userdata.sh")

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.compute_ec2_sg.id, aws_security_group.compute_ec2_ssh_sg.id]
  }
}

resource "aws_autoscaling_group" "compute_asg" {
  name                = "compute_asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = aws_subnet.pub_subnet[*].id
  target_group_arns   = [aws_lb_target_group.compute-tg.arn]

  launch_template {
    id      = aws_launch_template.compute_launch_template.id
    version = "$Latest"
  }
}

