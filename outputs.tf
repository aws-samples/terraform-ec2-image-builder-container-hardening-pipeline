output "container_info" {
  description = "Various AMI attributes."
  value       = aws_imagebuilder_container_recipe.container_image
  sensitive   = true
}