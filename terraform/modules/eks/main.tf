# EKS control plane, managed node group and EKS add-ons.

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  # Networking add-ons are installed below as EKS managed add-ons instead.
  bootstrap_self_managed_addons = false

  vpc_config {
    subnet_ids              = var.cluster_subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.public_access_cidrs
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  enabled_cluster_log_types = var.cluster_log_types

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# Node disks and metadata settings: 80 GiB encrypted gp3, IMDSv2 required.
resource "aws_launch_template" "nodes" {
  name_prefix = "${var.cluster_name}-nodes-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_disk_size
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.cluster_name}-${var.node_group_name}" })
  }

  tags = var.tags
}

locals {
  # Pod networking must exist before nodes join, or they never become Ready.
  addons_before_nodes = { for name, addon in var.addons : name => addon if contains(["vpc-cni", "kube-proxy"], name) }
  addons_after_nodes  = { for name, addon in var.addons : name => addon if !contains(["vpc-cni", "kube-proxy"], name) }

  ebs_csi_configuration = jsonencode({ controller = { replicaCount = var.ebs_csi_controller_replicas } })
}

resource "aws_eks_addon" "before_nodes" {
  for_each = local.addons_before_nodes

  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = each.key
  addon_version               = each.value.version
  configuration_values        = each.value.configuration_values
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.node_subnet_ids

  ami_type       = var.node_ami_type
  capacity_type  = var.node_capacity_type
  instance_types = var.node_instance_types

  scaling_config {
    min_size     = var.node_min_size
    max_size     = var.node_max_size
    desired_size = var.node_desired_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  tags = var.tags

  # Scaling the group by hand (eksctl scale, console) shouldn't show up as drift.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node,
    aws_eks_addon.before_nodes,
  ]
}

resource "aws_eks_addon" "after_nodes" {
  for_each = local.addons_after_nodes

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.key
  addon_version = each.value.version

  configuration_values = each.key == "aws-ebs-csi-driver" ? coalesce(each.value.configuration_values, local.ebs_csi_configuration) : each.value.configuration_values

  service_account_role_arn = each.key == "aws-ebs-csi-driver" ? aws_iam_role.ebs_csi.arn : null

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  # CoreDNS, metrics-server and the EBS CSI controller need nodes to run on.
  depends_on = [aws_eks_node_group.this]
}
