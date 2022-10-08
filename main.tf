resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "sds-midterm-vpc"
  }
}

resource "aws_key_pair" "key_auth" {
  key_name   = "sds-midterm"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_eip" "web" {
  network_interface = aws_network_interface.web.id
  tags = {
    Name = "midterm-web-eip"
  }
}

resource "aws_eip" "nat" {
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

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnet_public_2.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
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
  subnet_id = aws_subnet.subnet_public_1.id

  security_groups = [aws_security_group.web.id]
  tags = {
    Name = "web"
  }
}

resource "aws_network_interface" "web_db" {
  subnet_id = aws_subnet.subnet_private_1.id

  security_groups = [aws_security_group.web_db.id]
  tags = {
    Name = "web_db"
  }
}

resource "aws_network_interface" "db_web" {
  subnet_id = aws_subnet.subnet_private_1.id

  security_groups = [aws_security_group.db_web.id]
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


resource "aws_route_table" "to_nat" {
  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
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
  route_table_id = aws_route_table.to_igw.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.subnet_private_2.id
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


resource "aws_security_group" "db_web" {
  name   = "db_web"
  vpc_id = aws_vpc.vpc_main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db_web"
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

resource "aws_instance" "web" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.key_auth.id
  depends_on    = [aws_instance.db]

  iam_instance_profile = aws_iam_instance_profile.web_instance_profile.id

  network_interface {
    network_interface_id = aws_network_interface.web.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.web_db.id
    device_index         = 1
  }

user_data = (templatefile("wordpress.tftpl", {
    database_host = aws_network_interface.db_web.private_ip
    database_name = var.database_name
    database_user = var.database_user
    database_pass = var.database_pass
    bucket_name   = var.bucket_name
    region        = var.region
    web_public_ip = aws_eip.web.public_ip
    admin_user    = var.admin_user
    admin_pass    = var.admin_pass
  }))

  tags = {
    Name = "web"
  }
}


resource "aws_instance" "db" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.key_auth.id

  network_interface {
    network_interface_id = aws_network_interface.db.id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.db_web.id
    device_index         = 1
  }


  user_data = (templatefile("install-db.tftpl", {
    database_name = var.database_name
    database_user = var.database_user
    database_pass = var.database_pass
  }))
  tags = {
    Name = "db"
  }
}


# Create an IAM role for the Web Servers.
resource "aws_iam_role" "web_iam_role" {
  name               = "web_iam_role"
  assume_role_policy = (file("iam_role.json"))

}

resource "aws_iam_instance_profile" "web_instance_profile" {
  name = "web_instance_profile_1"
  role = aws_iam_role.web_iam_role.id
}

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "bucket" {
  bucket = aws_s3_bucket.main.id
  acl    = "public-read"
}

resource "aws_iam_role_policy" "web_iam_role_policy" {
  name   = "web_iam_role_policy"
  role   = aws_iam_role.web_iam_role.id
  policy = (templatefile("iam_role_policy.tftpl",{
	bucket_name = var.bucket_name
  }))
}