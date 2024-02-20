resource "aws_vpc" "eks_cluster_vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "eks-cluster-vpc"
  }
}


resource "aws_internet_gateway" "eks_cluster_igw" {
  vpc_id = aws_vpc.eks_cluster_vpc.id

  tags = {
    Name = "eks-cluster-igw"
  }
}


resource "aws_subnet" "eks_cluster_vpc_publicSN-1a" {
  vpc_id = aws_vpc.eks_cluster_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-cluster-vpc-publicSN-1a"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "eks_cluster_vpc_publicSN-1b" {
  vpc_id = aws_vpc.eks_cluster_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "eks-cluster-vpc-publicSN-1b"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


resource "aws_subnet" "eks_cluster_vpc_privateSN-1c" {
  vpc_id = aws_vpc.eks_cluster_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "eks-cluster-vpc-privateSN-1c"
  }
}

resource "aws_subnet" "eks_cluster_vpc_privateSN-1d" {
  vpc_id = aws_vpc.eks_cluster_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1d"

  tags = {
    Name = "eks-cluster-vpc-privateSN-1d"
  }
}


resource "aws_route_table" "eks_cluster_vpc_publicRT" {
  vpc_id = aws_vpc.eks_cluster_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_cluster_igw.id
  }

  tags = {
    Name = "eks-cluster-vpc-publicRT"
  }
}


resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.eks_cluster_vpc_publicSN-1a.id
  route_table_id = aws_route_table.eks_cluster_vpc_publicRT.id
}

resource "aws_route_table_association" "b" {
  subnet_id = aws_subnet.eks_cluster_vpc_publicSN-1b.id
  route_table_id = aws_route_table.eks_cluster_vpc_publicRT.id
}


resource "aws_eip" "eks_cluster_vpc_eip1" {

  tags = {
    Name = "eks-cluster-vpc-eip1"
  }
}


resource "aws_nat_gateway" "eks_cluster_vpc_nat1" {
  subnet_id = aws_subnet.eks_cluster_vpc_publicSN-1a.id  # Adjust subnet as needed

  allocation_id = aws_eip.eks_cluster_vpc_eip1.allocation_id

  tags = {
    Name = "eks-cluster-vpc-nat1"
  }
}


resource "aws_eks_cluster" "eks_cluster" {
  name = "eks_cluster"
  role_arn = "arn:aws:iam::575359586957:role/eks-cluster-role"
  vpc_config {
    subnet_ids = [
      aws_subnet.eks_cluster_vpc_publicSN-1a.id,
      aws_subnet.eks_cluster_vpc_publicSN-1b.id,
      aws_subnet.eks_cluster_vpc_privateSN-1c.id,
      aws_subnet.eks_cluster_vpc_privateSN-1d.id,
    ]
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }
}


resource "aws_security_group" "eks_cluster_sg" {
  vpc_id = aws_vpc.eks_cluster_vpc.id

  ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}
