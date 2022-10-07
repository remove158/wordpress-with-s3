resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "sds-midterm-vpc"
  }
}

resource "aws_eip" "web" {
  network_interface = aws_network_interface.web.id
  tags = {
    Name = "midterm-web-eip"
  }
}

resource "aws_eip" "nat" {
  network_interface = aws_network_interface.nat.id
  tags = {
    Name = "midterm-nat-eip"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.vpc_main.id

  tags = {
    Name = "sds-igw"
  }
}

resource "aws_subnet" "subnet_public_1" {
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "sds_public_1"
  }
}

resource "aws_subnet" "subnet_public_2" {
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "sds_public_2"
  }
}

resource "aws_subnet" "subnet_private_1" {
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "sds_private_1"
  }
}

resource "aws_subnet" "subnet_private_2" {
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "sds_private_2"
  }
}

resource "aws_route_table" "to_igw" {
  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "table_igw"
  }
}

resource "aws_network_interface" "web" {
  subnet_id       = aws_subnet.subnet_public_1.id
  security_groups = [aws_security_group.web.id]

  tags = {
    Name = "web"
  }
}

resource "aws_network_interface" "web_db" {
  subnet_id       = aws_subnet.subnet_private_1.id
  security_groups = [aws_security_group.web_db.id]

  tags = {
    Name = "web_db"
  }
}

resource "aws_network_interface" "db" {
  subnet_id       = aws_subnet.subnet_private_2.id
  security_groups = [aws_security_group.db.id]

  tags = {
    Name = "db"
  }
}

resource "aws_network_interface" "nat" {
  subnet_id = aws_subnet.subnet_public_2.id

  tags = {
    Name = "nat"
  }
}

resource "aws_route_table" "to_nat" {
  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "table_nat"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.subnet_public_1.id
  route_table_id = aws_route_table.to_igw.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.subnet_public_2.id
  route_table_id = aws_route_table.to_nat.id
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.vpc_main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web"
  }
}

resource "aws_security_group" "web_db" {
  name   = "web_db"
  vpc_id = aws_vpc.vpc_main.id


  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "web_db"
  }
}

resource "aws_security_group" "db" {
  name   = "db"
  vpc_id = aws_vpc.vpc_main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "db"
  }
}