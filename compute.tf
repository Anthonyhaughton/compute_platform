resource "aws_launch_template" "compute_launch_template" {
  name          = "compute-lt"
  instance_type = "t2.micro"
  image_id      = "ami-0152204c1a187337c"
  user_data     = filebase64("${path.module}/userdata.sh")

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.compute_ec2_sg.id]
  }
}

resource "aws_autoscaling_group" "compute_asg" {
  name                = "compute_asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 4
  vpc_zone_identifier = aws_subnet.priv_subnet[*].id
  target_group_arns   = [aws_lb_target_group.compute-tg.arn]

  launch_template {
    id      = aws_launch_template.compute_launch_template.id
    version = "$Latest"
  }
}
