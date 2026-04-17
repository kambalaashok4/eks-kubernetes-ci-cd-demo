terraform {
  backend "s3" {
    bucket       = "eks-kubernetes-ci-cd-demo"
    region       = "us-east-1"
    key          = "EKS-TF/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
  required_version = ">=1.14.0"
  required_providers {
    aws = {
      version = ">= 5.49.0"
      source  = "hashicorp/aws"
    }
  }
}