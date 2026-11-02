variable "aws_region" {
  description = "AWS region for the EKS lab. Use eu-central-1 by default."
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project prefix used for naming resources."
  type        = string
  default     = "eks-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (load balancers, NAT)."
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (EKS nodes, Lambda)."
  type        = list(string)
  default     = ["10.30.11.0/24", "10.30.12.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for the database subnets (RDS)."
  type        = list(string)
  default     = ["10.30.21.0/24", "10.30.22.0/24"]
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group (Graviton/ARM)."
  type        = list(string)
  default     = ["t4g.medium"]
}

variable "node_min_size" {
  description = "Minimum nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_desired_size" {
  description = "Initial desired nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes in the managed node group."
  type        = number
  default     = 3
}

variable "cluster_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Restrict to your own IP (x.x.x.x/32) where possible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "extra_eks_admin_arns" {
  description = "Additional IAM principal ARNs granted cluster-admin through EKS access entries (e.g. when the console identity differs from the Terraform identity)."
  type        = list(string)
  default     = []
}

variable "db_instance_class" {
  description = "RDS instance class for the Multi-AZ PostgreSQL instance."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_engine_major_version" {
  description = "PostgreSQL major version, also used for the parameter group family."
  type        = string
  default     = "16"
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the RDS instance. The password is generated and stored in AWS Secrets Manager by RDS."
  type        = string
  default     = "postgresadmin"
}

variable "alert_email" {
  description = "Optional email address subscribed to the audit SNS topic. Leave empty to skip the subscription."
  type        = string
  default     = ""
}
