# Creates all networking infrastructure needed to deploy container image in Private Subnet with a NAT Gateway
# Amazon Linux Container images currently need internet access in order to bootstrap by AWSTOE
# VPC Endpoints cannot be used
# This solution can be modified to utilize only VPC Endpoints when the bootstrap process is updated
resource "aws_vpc" "hardening_pipeline" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}
resource "aws_subnet" "hardening_pipeline_public" {
  depends_on = [
    aws_vpc.hardening_pipeline
  ]

  vpc_id                  = aws_vpc.hardening_pipeline.id
  cidr_block              = "192.168.0.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public"
  }
}
resource "aws_subnet" "hardening_pipeline_private" {
  depends_on = [
    aws_vpc.hardening_pipeline,
    aws_subnet.hardening_pipeline_public
  ]

  vpc_id            = aws_vpc.hardening_pipeline.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${var.vpc_name}-private"
  }
}
resource "aws_internet_gateway" "hardening_pipeline_igw" {
  depends_on = [
    aws_vpc.hardening_pipeline,
    aws_subnet.hardening_pipeline_public,
    aws_subnet.hardening_pipeline_private
  ]

  vpc_id = aws_vpc.hardening_pipeline.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}
resource "aws_route_table" "hardening_pipeline_public_rt" {
  depends_on = [
    aws_vpc.hardening_pipeline,
    aws_internet_gateway.hardening_pipeline_igw
  ]
  vpc_id = aws_vpc.hardening_pipeline.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hardening_pipeline_igw.id
  }
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}
resource "aws_route_table_association" "hardening_pipeline_rt_assoc" {
  depends_on = [
    aws_vpc.hardening_pipeline,
    aws_subnet.hardening_pipeline_public,
    aws_subnet.hardening_pipeline_private,
    aws_route_table.hardening_pipeline_public_rt
  ]
  subnet_id      = aws_subnet.hardening_pipeline_public.id
  route_table_id = aws_route_table.hardening_pipeline_public_rt.id
}
resource "aws_eip" "nat_gateway_eip" {
  depends_on = [
    aws_route_table_association.hardening_pipeline_rt_assoc
  ]
  vpc = true
}
resource "aws_nat_gateway" "hardening_pipeline_nat_gateway" {
  depends_on = [
    aws_eip.nat_gateway_eip
  ]
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.hardening_pipeline_public.id
  tags = {
    Name = "${var.vpc_name}-nat-gateway"
  }
}
resource "aws_route_table" "hardening_pipeline_nat_gateway_rt" {
  depends_on = [
    aws_nat_gateway.hardening_pipeline_nat_gateway
  ]
  vpc_id = aws_vpc.hardening_pipeline.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hardening_pipeline_nat_gateway.id
  }
  tags = {
    Name = "${var.vpc_name}-nat-gateway-rt"
  }
}
resource "aws_route_table_association" "hardening_pipeline_nat_gw_rt_assoc" {
  depends_on = [
    aws_route_table.hardening_pipeline_nat_gateway_rt
  ]
  subnet_id      = aws_subnet.hardening_pipeline_private.id
  route_table_id = aws_route_table.hardening_pipeline_nat_gateway_rt.id
}