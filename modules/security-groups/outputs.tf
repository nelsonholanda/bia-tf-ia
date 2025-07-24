output "bia_dev_sg_id" {
  description = "BIA development security group ID"
  value       = aws_security_group.bia_dev.id
}

output "bia_rds_sg_id" {
  description = "BIA RDS security group ID"
  value       = aws_security_group.bia_rds.id
}

output "bia_alb_sg_id" {
  description = "BIA ALB security group ID"
  value       = aws_security_group.bia_alb.id
}

output "bia_ec2_sg_id" {
  description = "BIA EC2 security group ID"
  value       = aws_security_group.bia_ec2.id
}

output "ecs_security_group_id" {
  description = "ECS security group ID (alias for EC2)"
  value       = aws_security_group.bia_ec2.id
}