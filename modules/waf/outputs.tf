output "web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = var.environment == "prod" ? aws_wafv2_web_acl.main[0].arn : null
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = var.environment == "prod" ? aws_wafv2_web_acl.main[0].id : null
}