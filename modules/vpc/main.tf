resource "aws_vpc" "main" {
  cidr_block           = var.environment == "dev" ? "172.16.48.0/20" : "172.16.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-vpc"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "public_subnet_us_east_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.environment == "dev" ? "172.16.48.0/27" : "172.16.0.0/27"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-public-us-east-1a"
    Type = "public"
    Tier = "public"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "public_subnet_us_east_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.environment == "dev" ? "172.16.48.32/27" : "172.16.0.32/27"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-public-us-east-1c"
    Type = "public"
    Tier = "public"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "public_subnet_us_east_1f" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.environment == "dev" ? "172.16.48.64/27" : "172.16.0.64/27"
  availability_zone       = "us-east-1f"
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-public-us-east-1f"
    Type = "public"
    Tier = "public"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "private_subnet_us_east_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.environment == "dev" ? "172.16.48.96/27" : "172.16.0.96/27"
  availability_zone = "us-east-1a"

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-private-us-east-1a"
    Type = "private"
    Tier = "private"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "private_subnet_us_east_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.environment == "dev" ? "172.16.48.128/27" : "172.16.0.128/27"
  availability_zone = "us-east-1c"

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-private-us-east-1c"
    Type = "private"
    Tier = "private"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_subnet" "private_subnet_us_east_1f" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.environment == "dev" ? "172.16.48.160/27" : "172.16.0.160/27"
  availability_zone = "us-east-1f"

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-subnet-private-us-east-1f"
    Type = "private"
    Tier = "private"
  })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-igw"
  })

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_subnet_us_east_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_subnet_us_east_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1f" {
  subnet_id      = aws_subnet.public_subnet_us_east_1f.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = var.env_config.create_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.env_config.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_subnet_us_east_1a.id

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-nat-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.env_config.create_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(var.tags, {
    Name = "bia-${var.environment}-private-rt"
  })
}

# Route table associations for private subnets
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_subnet_us_east_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_subnet_us_east_1c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_1f" {
  subnet_id      = aws_subnet.private_subnet_us_east_1f.id
  route_table_id = aws_route_table.private.id
}