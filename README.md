# eks-kubernetes-ci-cd-demo

This repository contains instructions and example Terraform code to deploy an Amazon EKS cluster with 2 nodes and install the minimal, required EKS add-ons (CoreDNS, kube-proxy, and the AWS VPC CNI). The goal is a small, production-like cluster suitable for CI/CD demos and learning.

## Summary

- Create an EKS cluster using Terraform (terraform-aws-modules/eks/aws).
- Create a managed node group with 2 EC2 worker nodes.
- Install minimal EKS add-ons:
  - CoreDNS
  - kube-proxy
  - AWS VPC CNI (aws-node)
- Verify the cluster and add-ons with kubectl.
- Tear down using `terraform destroy`.

## Prerequisites

- Terraform 1.0+ (recommend newest stable)
- AWS CLI v2 configured with credentials and default region
- kubectl installed (compatible with your EKS Kubernetes version)
- An AWS account with IAM permissions to create EKS, EC2, IAM, VPC, and related resources
- (Optional) jq for parsing CLI output

Minimum IAM permissions (for the user or role running Terraform):
- eks:CreateCluster, eks:DeleteCluster, eks:Describe*
- ec2:CreateVpc, ec2:DeleteVpc, ec2:*
- iam:CreateRole, iam:AttachRolePolicy, iam:DeleteRole, iam:*
- autoscaling / cloudformation / elb related permissions as required by node groups and VPC

If using an organizational policy, ensure Terraform can create roles, policies, subnets, security groups, etc.

## File layout (suggested)

- main.tf           -> provider, EKS module, add-ons
- variables.tf      -> variables and defaults
- outputs.tf        -> important outputs (cluster name, kubeconfig, endpoint)
- terraform.tfvars  -> local values (do not commit secrets)
- versions.tf       -> required providers & Terraform version

Below are example snippets you can paste into your Terraform files.

---

## Example Terraform (main.tf + variables.tf snippets)

main.tf (minimal example using terraform-aws-modules/eks/aws)
```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0" # choose a compatible module version

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  # Create a new VPC (set to false to use existing VPC/subnets)
  vpc_create = true

  # Node group (managed)
  node_groups = {
    demo_nodes = {
      desired_capacity = 2
      min_capacity     = 2
      max_capacity     = 2

      instance_type = "t3.medium"
      key_name      = var.ssh_key_name        # optional, for SSH
    }
  }

  manage_aws_auth = true
  # iam roles, additional options, tags, etc.
}
```

Add-ons using aws_eks_addon resources (works with EKS-managed add-ons)
```hcl
resource "aws_eks_addon" "coredns" {
  cluster_name       = module.eks.cluster_name
  addon_name         = "coredns"
  resolve_conflicts  = "OVERWRITE" # or NONE
  # addon_version    = "1.8.0-eksbuild.1" # optional pin
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "vpc-cni"
  resolve_conflicts = "OVERWRITE"
}
```

variables.tf
```hcl
variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "cluster_name" {
  type    = string
  default = "demo-eks-cluster"
}

variable "kubernetes_version" {
  type    = string
  default = "1.28" # pick a supported version
}

variable "ssh_key_name" {
  type    = string
  default = "" # set if you want SSH access to nodes
}
```

outputs.tf (examples)
```hcl
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig-cmd" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
```

Notes:
- If you prefer the older approach, install the add-ons by applying the relevant Kubernetes manifests or use `helm` (but using EKS managed add-ons is recommended for CoreDNS/kube-proxy/vpc-cni).
- The module can create VPC and subnets; adjust `vpc_create` and `vpc_id`, `subnet_ids` if you want to use an existing VPC.

---

## Deploy steps

1. Configure AWS credentials and region
```bash
aws configure
# or export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and AWS_REGION
export AWS_REGION=us-west-2
```

2. Initialize Terraform
```bash
terraform init
```

3. (Optional) Review the plan
```bash
terraform plan -var-file="terraform.tfvars"
```

4. Apply (creates VPC, EKS cluster, node group)
```bash
terraform apply -var-file="terraform.tfvars"
# or
terraform apply -auto-approve
```

Notes: first apply may take ~10–20 minutes to provision EKS and node group.

5. Configure kubectl
```bash
aws eks update-kubeconfig --region ${AWS_REGION} --name $(terraform output -raw cluster_name)
# or use the kubeconfig output path if you prefer
```

6. Verify cluster & add-ons
```bash
kubectl get nodes
kubectl get pods -n kube-system

# Check CoreDNS, kube-proxy, aws-node pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl get pods -n kube-system -l k8s-app=aws-node
```

You should see the pods for CoreDNS, kube-proxy, and aws-node running. If you used `aws_eks_addon` resources, Terraform managed those add-ons for you; you can see them in the AWS console under EKS -> Add-ons.

---

## Post-deploy suggestions (optional)

- Install metrics-server if you plan to use `kubectl top`:
  - Use the upstream metrics-server manifests or Helm chart.
- Install Cluster Autoscaler (requires IRSA and IAM policy) if you want auto-scaling.
- Implement IAM Roles for Service Accounts (IRSA) for safe permissions.
- Add OIDC provider: the EKS module can create an OIDC provider for IRSA.

---

## Upgrading and managing add-ons

- To upgrade an EKS-managed add-on version, update `addon_version` in the `aws_eks_addon` resource and `terraform apply`.
- You can also manage add-ons outside Terraform using `aws eks update-addon` or via the AWS Console.

---

## Cleanup

To remove everything:
```bash
terraform destroy -auto-approve
```
This will terminate the cluster, node groups, VPC (if created by the module), and attached resources.

---

## Troubleshooting

- If `kubectl` cannot connect, run:
  ```bash
  aws eks update-kubeconfig --region $AWS_REGION --name $(terraform output -raw cluster_name)
  ```
- If add-ons appear stuck, check AWS Console EKS → Clusters → <cluster> → Add-ons for status and logs.
- If nodes are not Ready, check `kubectl describe node <node>` and `kubectl logs` for kubelet/aws-node errors.
- Ensure your AWS account limits allow launching the EC2 instance types you chose.

---

## Security & cost notes

- This example creates EC2 instances and other billable resources—expect hourly charges while running.
- Use small instance types (t3.medium) for demo usage and delete resources when done.
- Do not commit `terraform.tfvars` with secrets and keys.

---

## Where to go next

- Add CI/CD pipelines to deploy Kubernetes manifests to this cluster (GitHub Actions, Jenkins, etc.).
- Add monitoring and logging (Prometheus, Grafana, EFK).
- Configure GitOps workflows (ArgoCD or Flux).

## License

MIT / choose your preferred license.
