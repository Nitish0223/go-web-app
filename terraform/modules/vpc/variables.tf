variable "name" {
  description = "Prefix for resource names."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, used in the subnet tags the AWS load balancer integration looks for."
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "One public subnet CIDR per availability zone, in the same order as azs."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "At least one public subnet is required."
  }
}

variable "private_subnet_cidrs" {
  description = "One private subnet CIDR per availability zone, in the same order as azs."
  type        = list(string)
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default     = {}
}
