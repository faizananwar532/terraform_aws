# AWS Credentials - Replace with your actual credentials
access_key = "YOUR_AWS_ACCESS_KEY"
secret_key = "YOUR_AWS_SECRET_KEY"

# AWS Region
region = "us-east-1"

# EKS Cluster Configuration
clustername = "staging"
spot_instance_types = ["t3.medium"]
spot_max_size = 10
spot_min_size = 2
spot_desired_size = 2

# ECR Repository Name
ecr_name = "trainings"