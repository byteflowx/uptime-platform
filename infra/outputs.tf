output "node_id" {
  value = aws_instance.node.id
}

output "node_public_ip" {
  value = aws_instance.node.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}
