# AWS CloudWatch Log Monitoring using Terraform

## Overview

This project provisions AWS resources using Terraform to automatically collect and forward EC2 system logs to Amazon CloudWatch Logs.

## Resources Created

- IAM Role for CloudWatch Agent
- IAM Instance Profile
- CloudWatch Log Group
- Security Group
- Amazon Linux 2023 EC2 Instance
- CloudWatch Agent Configuration
- IAM Policy Attachment for Log Access

## Deployment

Initialize Terraform:

```bash
terraform init
```

Validate configuration:

```bash
terraform validate
```

Review changes:

```bash
terraform plan
```

Deploy resources:

```bash
terraform apply -auto-approve
```

## Verification

1. Open AWS Console.
2. Navigate to **CloudWatch**.
3. Select **Log Groups**.
4. Open the created log group.
5. Verify logs from the EC2 instance are being received.

## Cleanup

Destroy all resources:

```bash
terraform destroy -auto-approve
```

## Project Information

**Project:** CloudWatch Log Monitoring Automation

**Tools Used:**
- Terraform
- AWS EC2
- AWS IAM
- Amazon CloudWatch
- Amazon Linux 2023
