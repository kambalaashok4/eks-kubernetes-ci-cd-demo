resource "aws_eks_cluster" "cluster" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = concat(
      aws_subnet.eks_public_subnet[*].id,
      aws_subnet.eks_private_subnet[*].id
    )

    security_group_ids      = [aws_security_group.eks_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

#   depends_on = [aws_iam_role_policy_attachment.AmazonEKSClusterPolicy]

  tags = {
    Name = "eks-cluster"
  }
}


resource "aws_launch_template" "eks_launch_template" {
  name_prefix   = "eks-launch-template-"
  instance_type = "t3.medium"
  # key_name      = "devops"
  image_id = "ami-07a5013b607bc21bf"

  user_data = base64encode(<<-EOF
#!/bin/bash
/etc/eks/bootstrap.sh ${aws_eks_cluster.cluster.name}
EOF
  )

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "eks-worker-node"
    }
  }
}


resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.NodeGroupRole.arn

  subnet_ids = concat(
    aws_subnet.eks_public_subnet[*].id
  )

  launch_template {
    id      = aws_launch_template.eks_launch_template.id
    version = "$Latest"
  }

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy
  ]

  tags = {
    Name = "eks-node-group"
  }
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "vpc-cni"
  addon_version = "v1.21.1-eksbuild.5"
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "metric_server" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "metrics-server"
  addon_version = "v0.8.1-eksbuild.2"
  resolve_conflicts_on_update = "PRESERVE"  
}



resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "kube-proxy"
  addon_version = "v1.35.0-eksbuild.2"
  resolve_conflicts_on_update = "PRESERVE"  
}
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.cluster.name
  addon_name   = "coredns"
  addon_version = "v1.13.2-eksbuild.3"
  resolve_conflicts_on_update = "PRESERVE"  
}