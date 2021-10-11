output "instance_id" {
  value = aws_instance.terraform-web-server.id

}

output "public_ip" {
  value = aws_eip.one.public_ip

}

output "private_ip" {
  value = aws_instance.terraform-web-server.private_ip

}

output "alb_dns_name" {
  value = aws_alb.alb.dns_name
}

output "subnet1" {
  value = aws_subnet.terraform-subnet1.id
  
}

output "subnet2" {
  value = aws_subnet.terraform-subnet2.id
}
