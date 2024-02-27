terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "eu-north-1"
}

resource "aws_eks_cluster" "bitirmeprojesi" {
  name     = "osman_eks"
  role_arn = "arn:aws:iam::998888128084:role/EksClusterRoleCagri"

  vpc_config {
    subnet_ids = [aws_subnet.example_subnet.id,aws_subnet.example_subnet2.id]
  }
  

  
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"  
}

resource "aws_subnet" "example_subnet" {
  vpc_id                  = aws_vpc.example_vpc.id  
  cidr_block              = "10.0.1.0/24"            
  availability_zone       = "eu-north-1a"             
  map_public_ip_on_launch = true                     
}

resource "aws_subnet" "example_subnet2" {
  vpc_id                  = aws_vpc.example_vpc.id 
  cidr_block              = "10.0.2.0/24"            
  availability_zone       = "eu-north-1b"             
  map_public_ip_on_launch = true                     



}
resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.bitirmeprojesi.name
  node_group_name = "bitirmeprojesi-workers"
  node_role_arn   = aws_iam_role.role.arn
  subnet_ids      = [aws_subnet.example_subnet.id, aws_subnet.example_subnet2.id]
  instance_types  = ["t3.medium"]
  ami_type        = "AL2_x86_64"

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 5
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "role" {
  name = "cagri-role"

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