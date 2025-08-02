output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    aws_subnet.public_subnet_us_east_1a.id,
    aws_subnet.public_subnet_us_east_1c.id,
    aws_subnet.public_subnet_us_east_1f.id
  ]
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [
    aws_subnet.public_subnet_us_east_1a.id,
    aws_subnet.public_subnet_us_east_1c.id,
    aws_subnet.public_subnet_us_east_1f.id
  ]
}

output "ecs_subnet_ids" {
  description = "List of subnet IDs for ECS deployment (public for dev, private for prod)"
  value = var.env_config.use_private_subnets ? [
    aws_subnet.private_subnet_us_east_1a.id,
    aws_subnet.private_subnet_us_east_1c.id,
    aws_subnet.private_subnet_us_east_1f.id
    ] : [
    aws_subnet.public_subnet_us_east_1a.id,
    aws_subnet.public_subnet_us_east_1c.id,
    aws_subnet.public_subnet_us_east_1f.id
  ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    aws_subnet.private_subnet_us_east_1a.id,
    aws_subnet.private_subnet_us_east_1c.id,
    aws_subnet.private_subnet_us_east_1f.id
  ]
}