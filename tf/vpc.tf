resource "aws_vpc" "us_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "us-vpc"
  }
}

resource "aws_internet_gateway" "us_vpc" {
  vpc_id = aws_vpc.us_vpc.id

  tags = {
    Name = "us-vpc-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = {
    public_a = {
      availability_zone = "eu-west-2a"
      cidr_block        = "10.0.1.0/24"
    }
    public_b = {
      availability_zone = "eu-west-2b"
      cidr_block        = "10.0.2.0/24"
    }
  }

  vpc_id                  = aws_vpc.us_vpc.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "us-vpc-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.us_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.us_vpc.id
  }

  tags = {
    Name = "us-vpc-public"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}
