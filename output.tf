output "web_ip" {
  value = aws_eip.web.public_ip
}

output "db_ip" {
  value = aws_network_interface.db_web.private_ip
}
