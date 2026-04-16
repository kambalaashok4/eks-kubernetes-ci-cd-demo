
variable "environment" {
    description = "Deployment environment (e.g., dev, staging, prod)"
    type        = string
    default     = "dev"
  
}

variable "region" {
    description = "region"
    default = "us-east-1"
  
}