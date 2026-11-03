resource "aws_iam_role" "eks_cluster" {
  name = "us-vpc-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "us_vpc" {
  name     = "us-vpc-eks"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [for subnet in aws_subnet.public : subnet.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

resource "aws_iam_role" "eks_worker" {
  name = "us-vpc-eks-worker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_worker.name
}

resource "aws_eks_node_group" "worker" {
  cluster_name    = aws_eks_cluster.us_vpc.name
  node_group_name = "us-vpc-worker"
  node_role_arn   = aws_iam_role.eks_worker.arn
  subnet_ids      = [for subnet in aws_subnet.public : subnet.id]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [aws_iam_role_policy_attachment.eks_worker]
}
