resource "aws_vpc" "web" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  instance_tenancy     = "default"

  tags = {
    "Name" = "WebserverVPC"
  }
}

resource "aws_subnet" "public-subnet" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.web.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    "Name" = format("public-subnet-%s", count.index)
  }
}

resource "aws_subnet" "private-subnet" {
  count                   = length(var.private_subnets)
  vpc_id                  = aws_vpc.web.id
  cidr_block              = var.private_subnets[count.index]
  map_public_ip_on_launch = "false"
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    "Name" = format("private-subnet-%s", count.index)
  }
}

resource "aws_internet_gateway" "web-igw" {
  vpc_id = aws_vpc.web.id

  tags = {
    "Name" = "web-igw"
  }
}

resource "aws_route_table" "web" {
  vpc_id = aws_vpc.web.id

  route = [{
    cidr_block                = "0.0.0.0/0"
    egress_only_gateway_id    = null
    gateway_id                = aws_internet_gateway.web-igw.id
    instance_id               = null
    ipv6_cidr_block           = null
    local_gateway_id          = null
    nat_gateway_id            = null
    network_interface_id      = null
    transit_gateway_id        = null
    vpc_endpoint_id           = null
    vpc_peering_connection_id = null
  }]

  tags = {
    "Name" = "web-route"
  }
}

resource "aws_route_table_association" "web-rta-public-subnet" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.web.id
}

resource "aws_eip" "nat-gateway-ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat-gateway-ip.id
  subnet_id     = aws_subnet.public-subnet[0].id
  tags = {
    "Name" = "NATGateway"
  }
}

resource "aws_route_table" "nat-gateway" {
  vpc_id = aws_vpc.web.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    "Name" = "nat-gateway"
  }
}

resource "aws_route_table_association" "nat-gateway" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.nat-gateway.id
}