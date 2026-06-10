output "alb_dns_name" {
  description = "DNS name for ALB"
  value       = aws_lb.compute_lb.dns_name
}