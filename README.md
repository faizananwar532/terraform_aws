# AWS EKS Infrastructure with Terraform

This repository contains Terraform code for provisioning an Amazon EKS cluster with associated networking components in AWS.

## Infrastructure Overview

This Terraform project creates the following AWS resources:

* **VPC** - A VPC with CIDR block 10.0.0.0/16
* **Subnets** - 2 public and 2 private subnets across 2 availability zones
* **NAT Gateways** - 2 NAT gateways for private subnet internet access
* **Internet Gateway** - For public subnet internet access
* **Route Tables** - Separate route tables for public and private subnets
* **EKS Cluster** - Named "staging" by default
* **EKS Node Group** - SPOT instance-based node group for cost optimization
* **ECR Repository** - For storing container images
* **IAM Roles and Policies** - For EKS cluster, node group, and EBS CSI driver
* **EBS CSI Driver** - Installed as an EKS add-on

## Prerequisites

* AWS CLI installed and configured
* Terraform (version >= 1.0.0)
* AWS account with appropriate permissions

## File Structure

```
.
├── main.tf         # Main Terraform configuration
├── variables.tf    # Variable declarations
├── terraform.tfvars # Variable values (you need to create this)
└── backend.tf      # Backend configuration (you need to create this)
```

## Getting Started

### 1. Create a `terraform.tfvars` file

Create a `terraform.tfvars` file with the following content:

```hcl
access_key      = "YOUR_AWS_ACCESS_KEY"
secret_key      = "YOUR_AWS_SECRET_KEY"
region          = "us-east-1"  # Change if needed
clustername     = "staging"    # Change if needed
spot_instance_types = ["t3.medium"]
spot_max_size   = 10
spot_min_size   = 2
spot_desired_size = 2
ecr_name        = "trainings"  # Change if needed
```

### 2. Set up S3 Backend

Create a bucket in AWS S3 to store the Terraform state file. Then create a `backend.tf` file:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "eks/staging/terraform.tfstate"
    region = "us-east-1"  # Change to match your bucket region
  }
}
```

### 3. Initialize Terraform

```bash
terraform init -backend-config=backend.tfvars
```

### 4. Plan and Apply

```bash
terraform plan
terraform apply
```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `access_key` | AWS access key | (sensitive) |
| `secret_key` | AWS secret key | (sensitive) |
| `region` | AWS region | `us-east-1` |
| `clustername` | EKS cluster name | `staging` |
| `spot_instance_types` | Instance types for spot nodes | `["t3.medium"]` |
| `spot_max_size` | Maximum number of nodes | `10` |
| `spot_min_size` | Minimum number of nodes | `2` |
| `spot_desired_size` | Desired number of nodes | `2` |
| `ecr_name` | ECR repository name | `trainings` |

## Outputs

After successful deployment, Terraform will output:

* NAT Gateway EIPs
* EKS Cluster Name
* EKS Cluster Endpoint
* EKS Cluster Security Group ID
* EKS Node Group Subnet IDs

## Working with the EKS Cluster

Once the cluster is created, you can configure `kubectl` to work with it:

```bash
aws eks update-kubeconfig --name staging --region us-east-1
```

## Notes

* This infrastructure uses SPOT instances for cost optimization
* The EBS CSI driver is installed as an EKS add-on for dynamic volume provisioning
* The cluster is configured with both public and private endpoints

## Security Considerations

* AWS credentials are marked as sensitive in variables.tf
* Remember to secure your terraform.tfvars file as it contains sensitive information
* Consider using AWS IAM roles instead of access keys for production environments