# VPC Module - Create VPC and subnets for multiple environments with dynamic AZs

# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create VPC with dynamic CIDR
resource "aws_vpc" "main" {
  cidr_block           = var.env_config.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-vpc"
  })

  lifecycle {
    prevent_destroy = false
  }
}

# Create public subnets dynamically
resource "aws_subnet" "public" {
  count                   = var.env_config.availability_zones
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.env_config.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-public-${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
    Type = "Public"
    Tier = "Web"
  })

  lifecycle {
    prevent_destroy = false
  }
}

# Create private subnets dynamically
resource "aws_subnet" "private" {
  count             = var.env_config.availability_zones
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.env_config.vpc_cidr, 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-private-${count.index + 1}-${data.aws_availability_zones.available.names[count.index]}"
    Type = "Private"
    Tier = "Application"
  })

  lifecycle {
    prevent_destroy = false
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-igw"
  })

  lifecycle {
    create_before_destroy = false
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-public-rt"
    Type = "Public"
  })
}

# Route table associations for public subnets
resource "aws_route_table_association" "public" {
  count          = var.env_config.availability_zones
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateways (one per AZ for production, one for dev)
resource "aws_eip" "nat" {
  count  = var.env_config.create_nat_gateway ? (var.environment == "prod" ? var.env_config.availability_zones : 1) : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.env_config.create_nat_gateway ? (var.environment == "prod" ? var.env_config.availability_zones : 1) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-nat-gateway-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  count  = var.env_config.create_nat_gateway ? (var.environment == "prod" ? var.env_config.availability_zones : 1) : 1
  vpc_id = aws_vpc.main.id

  # Add route to NAT Gateway if it exists
  dynamic "route" {
    for_each = var.env_config.create_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.environment == "prod" ? aws_nat_gateway.main[count.index].id : aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-private-rt-${count.index + 1}"
    Type = "Private"
  })
}

# Route table associations for private subnets
resource "aws_route_table_association" "private" {
  count          = var.env_config.availability_zones
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.environment == "prod" ? aws_route_table.private[count.index].id : aws_route_table.private[0].id
}

# VPC Endpoints for cost optimization and security
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([aws_route_table.public.id], aws_route_table.private[*].id)

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.environment == "prod" ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-ecr-dkr-endpoint"
  })
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.environment == "prod" ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-ecr-api-endpoint"
  })
}

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  count       = var.environment == "prod" ? 1 : 0
  name        = "bia-${var.environment}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-vpc-endpoints"
  })
}

# Data source for current region
data "aws_region" "current" {}