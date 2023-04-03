# VPC
resource "aws_vpc" "main" {
 cidr_block = "192.168.0.0/16"
 
 tags = {
   Name = "Main VPC"
 }
}

# Subnets publica
resource "aws_subnet" "public_subnets" {
 #count             = length(var.public_subnet_cidrs)
 vpc_id            = aws_vpc.main.id
 cidr_block        = "192.168.1.0/24"
 availability_zone = "us-east-2a"
 #cidr_block        = element(var.public_subnet_cidrs, count.index)
 #availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Public Subnet"
 }
}

# Subnets privada 
resource "aws_subnet" "private_subnets" {
 #count             = length(var.private_subnet_cidrs)
 vpc_id            = aws_vpc.main.id
 cidr_block        = "192.168.3.0/24"
 availability_zone = "us-east-2a"
 #cidr_block        = element(var.private_subnet_cidrs, count.index)
 #availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Private Subnet"
 }
}
# Route table public
resource "aws_route_table" "PU_RT" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.IGW.id
 }
 
 tags = {
   Name = "Main public - RT"
 }
}
# Route table private
resource "aws_route_table" "PR_RT" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_nat_gateway.NGW.id
 }
 
 tags = {
   Name = "Main private - RT"
 }
}

# Internet gateway
resource "aws_internet_gateway" "IGW" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "Main VPC IGW"
 }
}
# Elastic IP Nat
 resource "aws_eip" "NAT-ElasticIP" {
   vpc   = true
 }

 resource "aws_nat_gateway" "NGW" {
   allocation_id = aws_eip.NAT-ElasticIP.id
   subnet_id = aws_subnet.public_subnets.id

   tags = {
    Name = "Main VPC NGW"
   }  
 } 

#Asociacion de subnets publicas a route table publica
resource "aws_route_table_association" "public_subnet_association" {
 #count = length(var.public_subnet_cidrs)
 #subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 subnet_id  = aws_subnet.public_subnets.id
 route_table_id = aws_route_table.PU_RT.id
}

#Asociacion de subnets privadas a route table privada
resource "aws_route_table_association" "private_subnet_association" {
 #count = length(var.public_subnet_cidrs)
 #subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 subnet_id  = aws_subnet.private_subnets.id
 route_table_id = aws_route_table.PR_RT.id
}

#Grupoo de  seguridad
resource "aws_security_group" "EC2-Instance-SG" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.main.id

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
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#instancia EC2
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [aws_security_group.EC2-Instance-SG.id]
  instance_type = "t2.micro"
  key_name = "DevOps"
  subnet_id = aws_subnet.public_subnets.id
  associate_public_ip_address = true

  tags = {
    Name = "web-server"
  }
}


