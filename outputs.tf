output "instance_public_dns" {
  value = aws_instance.web.public_dns
}

output "aws_region" {
  value = var.AWS_REGION
}

output "nat-gateway-ip" {
  value = aws_eip.nat-gateway-ip.public_ip
}