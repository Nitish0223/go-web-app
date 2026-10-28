variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version of the control plane."
  type        = string
}

variable "cluster_subnet_ids" {
  description = "Subnets for the control plane's network interfaces (public and private)."
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnets the worker nodes run in."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API is reachable from the internet."
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the Kubernetes API is reachable from inside the VPC."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "service_ipv4_cidr" {
  description = "CIDR that Kubernetes Service IPs are allocated from."
  type        = string
  default     = "10.100.0.0/16"
}

variable "cluster_log_types" {
  description = "Control plane log types sent to CloudWatch, e.g. [\"api\", \"audit\"]. Empty disables logging."
  type        = list(string)
  default     = []
}

variable "node_group_name" {
  description = "Name of the managed node group."
  type        = string
  default     = "worker-nodes"
}

variable "node_instance_types" {
  description = "EC2 instance types for the worker nodes."
  type        = list(string)
}

variable "node_ami_type" {
  description = "EKS-optimized AMI family for the nodes."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Root volume size of each node, in GiB."
  type        = number
  default     = 80
}

variable "node_min_size" {
  description = "Minimum number of nodes."
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes."
  type        = number
}

variable "node_desired_size" {
  description = "Number of nodes to start with. Later changes (manual scaling) are ignored by Terraform."
  type        = number
}

variable "addons" {
  description = "EKS managed add-ons to install, keyed by add-on name. A null version uses the default for the Kubernetes version."
  type = map(object({
    version              = optional(string)
    configuration_values = optional(string)
  }))
}

variable "ebs_csi_controller_replicas" {
  description = "Replicas of the EBS CSI controller (the add-on default is 2)."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags added to every resource."
  type        = map(string)
  default     = {}
}
