# Create VPC
resource "aws_vpc" "vp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # To allow DNS resolution.
  enable_dns_hostnames = true

  tags = {
    Name = "vp-reaarch-vpc"
  }
}