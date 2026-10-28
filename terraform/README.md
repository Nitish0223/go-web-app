# Terraform: AWS infrastructure for go-web-app

Describes the infrastructure this project runs on: the VPC, the EKS cluster with its node group,
IAM roles and add-ons, and the in-cluster platform (ingress-nginx, cert-manager, Argo CD).
Argo CD then deploys the app and the monitoring stack from this repository (GitOps).

The running cluster was created with eksctl. These files reproduce the same setup as code; they are
not attached to that cluster. Applying them creates a new environment.

## Layout

```
terraform/
├── versions.tf          Terraform/provider versions, optional S3 backend
├── providers.tf         AWS, Helm and Kubernetes providers
├── variables.tf         Inputs (defaults match the running cluster)
├── main.tf              Wires the modules together
├── outputs.tf           Cluster details, DNS records to create, manual secrets
├── terraform.tfvars.example
└── modules/
    ├── vpc/             VPC, public/private subnets, internet + NAT gateway, routes
    ├── eks/             EKS cluster, node group, IAM roles, OIDC (IRSA), EKS add-ons
    └── platform/        Helm: ingress-nginx, cert-manager, Argo CD, bootstrap Applications
```

## Usage

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

After apply:

1. Run the `configure_kubectl` output to point kubectl at the cluster.
2. Create the secrets listed in the `manual_secrets` output. They hold passwords and tokens, so they
   are kept out of Terraform state and git.
3. Create the CNAME records from the `dns_records` output at the DNS provider.

To destroy, delete the Argo CD Applications first so Kubernetes removes the load balancer and EBS
volumes it created, then run `terraform destroy`.
