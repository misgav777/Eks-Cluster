resource "aws_vpc" "main" {
  cidr_block = var.vpc_cider_block


  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
    env  = var.env
  }
}

# IGW

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
    env  = var.env
  }

}

# NAT GATEWAY

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
    env  = var.env
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(aws_subnet.public[*].id, 0)

  tags = {
    Name = "${var.project_name}-nat-gw"
    env  = var.env
  }

  depends_on = [aws_internet_gateway.main]
}

# SUBNETS   
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    "Name"                                  = "${var.project_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/${var.eks_name}" = "owned"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    "Name"                                  = "${var.project_name}-private-${count.index + 1}"
    "kubernetes.io/role/internal-elb"       = "1"
    "kubernetes.io/cluster/${var.eks_name}" = "owned"
  }

}


# ROUTE TABLE
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
    env  = var.env
  }

}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
    env  = var.env
  }

}

# ROUTE TABLE ASSOCIATION

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = aws_route_table.private.id
}

