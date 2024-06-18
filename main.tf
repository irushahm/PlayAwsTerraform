# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
  }
}

#Create a subnet
resource "aws_subnet" "main-public-subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-public-subnet"
  }
}

#Create internet gateway
resource "aws_internet_gateway" "main-gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev-igw"
  }
}

#Create route table
resource "aws_route_table" "main-rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "dev-rt"
  }
}

#Create route
resource "aws_route" "default-route" {
  route_table_id         = aws_route_table.main-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main-gw.id
}

#Create route table association
resource "aws_route_table_association" "main-rta" {
  subnet_id      = aws_subnet.main-public-subnet.id
  route_table_id = aws_route_table.main-rt.id
}

#Create security group
resource "aws_security_group" "main-sg" {
  name        = "dev-sg"
  description = "Dev security group"
  vpc_id      = aws_vpc.main.id

  #Ingress rules
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#Create keypair
resource "aws_key_pair" "vm-auth" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/mainkey.pub")
}

#Create EC2 Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.vm-ami.id
  instance_type = "t2.micro"
  user_data     = file("customdata.tpl")

  #Associations
  key_name               = aws_key_pair.vm-auth.id
  vpc_security_group_ids = [aws_security_group.main-sg.id]
  subnet_id              = aws_subnet.main-public-subnet.id

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-vm"
  }

}
