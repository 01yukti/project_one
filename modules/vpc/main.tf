# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "example"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Configure two public subnet
resource "aws_subnet" "public" {
  count             = length(var.public_cidr)
  vpc_id            = var.vpc_id
  cidr_block        = var.public_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "public${count.index}"
  }
}

# Configure two private subnet
resource "aws_subnet" "private" {
  count             = length(var.private_cidr)
  vpc_id            = var.vpc_id
  cidr_block        = var.private_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "private${count.index}"
  }
}

#configure internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = var.vpc_id

  tags = {
    Name = "gw"
  }
}

#configure EIP
resource "aws_eip" "nat" {
  count = length(var.public_cidr)
  vpc   = true
}

#configure NAT gateway
resource "aws_nat_gateway" "nat_gw" {
  count = length(var.public_cidr)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id    = flatten(var.aws_subnet_public)[count.index]

  tags = {
    Name = "nat_gw"
  }
}
#Configure public route
resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id

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
  count          = length(var.public_cidr)
  subnet_id      = flatten(var.aws_subnet_public)[count.index]
  route_table_id = aws_route_table.public_rt.id
}

#Configure private route
resource "aws_route_table" "private_rt" {
  count  = length(var.public_cidr)
  #vpc_id = aws_vpc.example.id
  vpc_id = var.vpc_id

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
  count          = length(var.private_cidr)
  subnet_id      = flatten(var.aws_subnet_private)[count.index]
  route_table_id = aws_route_table.private_rt[count.index].id
}

output "vpc_id" {
  value = aws_vpc.example.id
}

output "aws_subnet_public" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "aws_subnet_private" {
  value = [for subnet in aws_subnet.private : subnet.id]
}