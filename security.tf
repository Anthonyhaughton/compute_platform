## -- ALB Security Group
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

## -- Compute Security Group
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

resource "aws_vpc_security_group_egress_rule" "ec2_egress_rule" {
  security_group_id = aws_security_group.compute_ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Needed so EC2 can pull packages during bootstrap
}
