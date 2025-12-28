# Create VPC
resource "aws_vpc" "vp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # To allow DNS resolution.
  enable_dns_hostnames = true

  tags = {
    Name = "vp-reaarch-vpc"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true # Important for public subnet

  tags = {
    Name = "public-subnet-vpro"
  }
}