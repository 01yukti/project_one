# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example"
  }
}

# Define local var for public and private cidr
locals {
  public_cidr  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_cidr = ["10.0.2.0/24", "10.0.3.0/24"]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Configure two public subnet
resource "aws_subnet" "public" {
  count             = length(local.public_cidr)
  vpc_id            = aws_vpc.example.id
  cidr_block        = local.public_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public${count.index}"
  }
}

# Configure two private subnet
resource "aws_subnet" "private" {
  count             = length(local.private_cidr)
  vpc_id            = aws_vpc.example.id
  cidr_block        = local.private_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private${count.index}"
  }
}

#configure internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "gw"
  }
}

#configure EIP
resource "aws_eip" "nat" {
  count = length(local.public_cidr)
  vpc   = true
}

#configure NAT gateway
resource "aws_nat_gateway" "nat_gw" {
  count = length(local.public_cidr)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "nat_gw"
  }
}
#Configure public route
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.example.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public_rt"
  }
}

#associate public subnet with public route tables
resource "aws_route_table_association" "pu_ta" {
  count          = length(local.public_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

#Configure private route
resource "aws_route_table" "private_rt" {
  count  = length(local.public_cidr)
  vpc_id = aws_vpc.example.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "private_rt"
  }
}

#associate private subnet with private route tables
resource "aws_route_table_association" "pr_ta" {
  count          = length(local.private_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

resource "aws_route53_zone" "primary" {
  name = "yukti.click"

  tags = {
    Name = "primary"
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.yukti.click"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
