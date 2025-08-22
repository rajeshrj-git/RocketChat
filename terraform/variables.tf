variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID for ECR"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "rocketchat-cluster"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "VPC ID where EKS cluster will be deployed"
  type        = string
}

variable "subnets" {
  description = "List of subnet IDs for the EKS worker nodes"
  type        = list(string)
}
