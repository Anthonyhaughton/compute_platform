# AWS Compute Platform with Auto Scaling & ALB

This repository contains a Terraform configuration to deploy a highly available, auto-scaled, and load-balanced web application on AWS. 

## Architecture Overview

The infrastructure is designed with AWS best practices for security and high availability:

* **Custom VPC**: A VPC with a CIDR block of `10.0.0.0/16`.
* **Public Subnets**: Two public subnets distributed across two Availability Zones (`us-east-1a` and `us-east-1b`) hosting the Application Load Balancer.
* **Private Subnets**: Two private subnets hosting the backend EC2 instances, isolating them from direct public internet access.
* **NAT Gateway**: A NAT Gateway in the public subnet associated with an Elastic IP, enabling instances in the private subnets to download packages (e.g., Apache HTTP server) during bootstrapping.
* **Application Load Balancer (ALB)**: Listens on port `80` (HTTP) and forwards requests to the healthy EC2 instances in the target group.
* **Auto Scaling Group (ASG)**: Launches and maintains a desired capacity of `2` EC2 instances (`t2.micro` running Amazon Linux) in the private subnets.
* **Self-Bootstrapping**: Instances run a User Data startup script (`userdata.sh`) upon launch to update packages, install, and run Apache.

---

## Getting Started

### Prerequisites
* [Terraform](https://developer.hashicorp.com/terraform/downloads) CLI installed.
* AWS credentials configured locally (e.g., via `aws configure` or environment variables).

### Deployment Steps

1. **Initialize Terraform**:
   Downloads the required AWS providers.
   ```bash
   terraform init
   ```

2. **Validate Configuration**:
   Ensures there are no syntax or configuration errors.
   ```bash
   terraform validate
   ```

3. **Preview Changes**:
   Generates an execution plan showing exactly what resources will be created.
   ```bash
   terraform plan
   ```

4. **Apply Changes**:
   Deploy the infrastructure to AWS.
   ```bash
   terraform apply
   ```

5. **Verify the Deployment**:
   Once the apply finishes, Terraform will output the `alb_dns_name`. Paste this URL into your browser to verify you see the "Hello from the Compute Platform" homepage.
