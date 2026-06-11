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
