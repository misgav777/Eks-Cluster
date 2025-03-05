resource "aws_iam_role" "nodes" {
  name = "${var.project_name}-eks-nodes-role"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "nodes" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  role       = aws_iam_role.nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.project_name}-eks-nodes"
  node_role_arn   = aws_iam_role.nodes.arn
  version         = var.eks_version

  subnet_ids = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]
  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 0
  }

  capacity_type  = "ON_DEMAND"
  instance_types = [var.instance_type]

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }



  depends_on = [
    aws_iam_role_policy_attachment.cni,
    aws_iam_role_policy_attachment.ecr_policy,
    aws_iam_role_policy_attachment.nodes
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
