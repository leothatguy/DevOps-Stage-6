output "server_ip" {
  description = "Public IP address of the web server"
  value       = aws_instance.todo_app.public_ip
}

output "server_id" {
  description = "ID of the web server instance"
  value       = aws_instance.todo_app.id
}
