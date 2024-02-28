terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "eu-north-1"
}

resource "aws_eks_cluster" "bitirmeprojesi" {
  name     = "bitirmeprojesi_eks"
  role_arn = "arn:aws:iam::998888128084:role/EksClusterRoleCagri"

  vpc_config {
    subnet_ids = [aws_subnet.private-eu-north-1a.id, aws_subnet.private-eu-north-1b.id, aws_subnet.public-eu-north-1a.id, aws_subnet.public-eu-north-1b.id]
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # VPC için CIDR bloğunu buraya girin
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "private-eu-north-1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "eu-north-1a"
}

resource "aws_subnet" "private-eu-north-1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "eu-north-1b"
}

resource "aws_subnet" "public-eu-north-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-eu-north-1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-eu-north-1a.id
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      nat_gateway_id             = aws_nat_gateway.nat.id
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      gateway_id                 = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
      core_network_arn           = ""
    },
  ]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route = [
    {
      cidr_block                 = "0.0.0.0/0"
      gateway_id                 = aws_internet_gateway.igw.id
      nat_gateway_id             = ""
      carrier_gateway_id         = ""
      destination_prefix_list_id = ""
      egress_only_gateway_id     = ""
      instance_id                = ""
      ipv6_cidr_block            = ""
      local_gateway_id           = ""
      network_interface_id       = ""
      transit_gateway_id         = ""
      vpc_endpoint_id            = ""
      vpc_peering_connection_id  = ""
      core_network_arn           = ""
    },
  ]
}

resource "aws_route_table_association" "private-eu-north-1a" {
  subnet_id      = aws_subnet.private-eu-north-1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-eu-north-1b" {
  subnet_id      = aws_subnet.private-eu-north-1b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public-eu-north-1a" {
  subnet_id      = aws_subnet.public-eu-north-1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-eu-north-1b" {
  subnet_id      = aws_subnet.public-eu-north-1b.id
  route_table_id = aws_route_table.public.id
}



resource "aws_eks_node_group" "private-node" {
  cluster_name    = aws_eks_cluster.bitirmeprojesi.name
  node_group_name = "bitirmeprojesi-workers"
  node_role_arn   = aws_iam_role.role.arn
  subnet_ids = [aws_subnet.private-eu-north-1a.id, aws_subnet.private-eu-north-1b.id]
  instance_types  = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = 3
    min_size     = 3
    max_size     = 6
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "role" {
  name = "eksWorkerNodeRoleCagri"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.role.name
}
