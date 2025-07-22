output "EC2_instance_id" {
  value = aws_instance.web.public_ip
}
