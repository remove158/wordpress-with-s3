resource "aws_vpc" "vpc_main" {
  cidr_block           = "10.0.0.0/16"
  tags = {
    Name = "sds-midterm-vpc"
  }
}

resource "aws_subnet" "subnet_public_1" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       =  var.availability_zone

  tags = {
    Name = "sds_public_1"
  }
}

resource "aws_subnet" "subnet_public_2" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       =  var.availability_zone

  tags = {
    Name = "sds_public_2"
  }
}

resource "aws_subnet" "subnet_private_1" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       =  var.availability_zone

  tags = {
    Name = "sds_private_1"
  }
}

resource "aws_subnet" "subnet_private_2" {
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = "10.0.102.0/24"
  availability_zone       =  var.availability_zone

  tags = {
    Name = "sds_private_2"
  }
}
