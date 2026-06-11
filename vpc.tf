locals {
  # Define the exact zones you want to target
  target_zones = ["us-east-1a", "us-east-1b"]
}

# Create a VPC 
resource "aws_vpc" "compute_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "pub_subnet" {
  count             = length(local.target_zones)
  vpc_id            = aws_vpc.compute_vpc.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = local.target_zones[count.index]
}

resource "aws_subnet" "priv_subnet" {
  count             = length(local.target_zones)
  vpc_id            = aws_vpc.compute_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = local.target_zones[count.index]
}

resource "aws_eip" "nat-eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "compute-nat-gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.pub_subnet[0].id
  depends_on    = [aws_internet_gateway.compute_igw]
}

resource "aws_internet_gateway" "compute_igw" {
  vpc_id = aws_vpc.compute_vpc.id
}

resource "aws_route_table" "compute-public-rt" {
  vpc_id = aws_vpc.compute_vpc.id
}

resource "aws_route_table" "compute-private-rt" {
  vpc_id = aws_vpc.compute_vpc.id
}

resource "aws_route" "compute-public-route" {
  route_table_id         = aws_route_table.compute-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.compute_igw.id
}

resource "aws_route" "compute-private-route" {
  route_table_id         = aws_route_table.compute-private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.compute-nat-gw.id
}

resource "aws_route_table_association" "compute-rta" {
  count          = length(local.target_zones)
  subnet_id      = aws_subnet.pub_subnet[count.index].id
  route_table_id = aws_route_table.compute-public-rt.id
}

resource "aws_route_table_association" "compute-rta-private" {
  count          = length(local.target_zones)
  route_table_id = aws_route_table.compute-private-rt.id
  subnet_id      = aws_subnet.priv_subnet[count.index].id
}
