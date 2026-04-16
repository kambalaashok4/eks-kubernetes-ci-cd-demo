provider "aws" {
    region = var.region
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "eks-vpc"
  }
  region = var.region
}

resource "aws_subnet" "eks_public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "eks-public-subnet-${count.index + 1}"
  }
  
}

resource "aws_subnet" "eks_private_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "10.0.${count.index + 3}.0/24"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false
  tags = {
    Name = "eks-private-subnet-${count.index + 1}"
  }
  
}

resource "aws_route_table" "eks_rtb" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-route-table"
  }
  
}

resource "aws_route" "eks_route" {
  route_table_id         = aws_route_table.eks_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}


resource "aws_route_table_association" "eks_public_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.eks_public_subnet[count.index].id
  route_table_id = aws_route_table.eks_rtb.id
  
}

resource "aws_route_table_association" "eks_private_subnet_association" {
  count          = 2
  subnet_id      = aws_subnet.eks_private_subnet[count.index].id
  route_table_id = aws_route_table.eks_rtb.id
  
}

resource "aws_security_group" "eks_sg" {
  name        = "eks-security-group"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.eks_vpc.id
}


resource "aws_security_group_rule" "eks_sg_ingress" {
  type        = "ingress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_sg.id
}

resource "aws_security_group_rule" "eks_sg_ingress-1" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_sg.id
}

resource "aws_security_group_rule" "eks_sg_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_sg.id
}

resource "aws_security_group_rule" "eks_sg_egress-1" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_sg.id
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "eks-internet-gateway"
  }
  
}
    



##removed

