# BIA Infrastructure Project

BIA is a containerized web application deployed on AWS using ECS (Elastic Container Service). The infrastructure is managed as code using Terraform and supports two environments: development and production.

## Key Features

- **Multi-environment support**: Separate dev and prod configurations with environment-specific resource sizing
- **Container orchestration**: ECS cluster with auto-scaling capabilities
- **Database**: PostgreSQL RDS with Multi-AZ support in production
- **Load balancing**: Application Load Balancer with health checks
- **Security**: WAF protection in production, KMS encryption, and Secrets Manager for credentials
- **Monitoring**: CloudWatch logs and metrics with Container Insights in production
- **Cost optimization**: Resource scaling based on environment needs

## Architecture

The application follows a standard 3-tier architecture:
- **Presentation**: Application Load Balancer
- **Application**: ECS containers running the BIA application
- **Data**: RDS PostgreSQL database

## Owner

Project owned by Nelson Holanda for internal BIA application use.