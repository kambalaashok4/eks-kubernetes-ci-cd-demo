output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.cluster.name
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.cluster.arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = aws_eks_cluster.cluster.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64-encoded cluster certificate authority data"
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
  sensitive   = true
}

output "eks_node_group_name" {
  description = "Managed EKS node group name"
  value       = aws_eks_node_group.eks_node_group.node_group_name
}

output "eks_node_group_arn" {
  description = "Managed EKS node group ARN"
  value       = aws_eks_node_group.eks_node_group.arn
}

output "eks_node_group_status" {
  description = "Managed EKS node group status"
  value       = aws_eks_node_group.eks_node_group.status
}

output "eks_launch_template_id" {
  description = "EC2 launch template ID used by the node group"
  value       = aws_launch_template.eks_launch_template.id
}

output "eks_launch_template_latest_version" {
  description = "Latest version of the EC2 launch template"
  value       = aws_launch_template.eks_launch_template.latest_version
}

output "vpc_id" {
  description = "VPC ID for the EKS cluster"
  value       = aws_vpc.eks_vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the environment"
  value       = aws_subnet.eks_public_subnet[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the environment"
  value       = aws_subnet.eks_private_subnet[*].id
}

output "eks_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_sg.id
}

output "route_table_id" {
  description = "Route table ID associated with the subnets"
  value       = aws_route_table.eks_rtb.id
}

output "internet_gateway_id" {
  description = "Internet gateway ID for the VPC"
  value       = aws_internet_gateway.eks_igw.id
}

output "eks_cluster_role_arn" {
  description = "IAM role ARN used by the EKS control plane"
  value       = aws_iam_role.eks_role.arn
}

output "eks_node_role_arn" {
  description = "IAM role ARN used by the EKS worker nodes"
  value       = aws_iam_role.NodeGroupRole.arn
}
