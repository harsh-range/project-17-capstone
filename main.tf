terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

locals {
  log_group_name = "harsh-log-group"
}

resource "aws_cloudwatch_log_group" "harsh_logs" {
  name              = local.log_group_name
  retention_in_days = 1
}

resource "aws_iam_role" "cloudwatch_ec2_role" {
  name = "harsh-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"

        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "agent_policy_attach" {
  role       = aws_iam_role.cloudwatch_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch_profile" {
  name = "harsh-cloudwatch-profile"
  role = aws_iam_role.cloudwatch_ec2_role.name
}

data "aws_vpc" "default_vpc" {
  default = true
}

resource "aws_security_group" "monitoring_sg" {
  name        = "harsh-monitoring-sg"
  description = "Security group for CloudWatch logging instance"
  vpc_id      = data.aws_vpc.default_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Purpose = "Logging"
  }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "log_source_server" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.cloudwatch_profile.name
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]

  user_data = <<-USERDATA
#!/bin/bash

dnf install -y rsyslog amazon-cloudwatch-agent

systemctl enable rsyslog
systemctl start rsyslog

logger "Initial harsh log generated"

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${local.log_group_name}",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-s \
-c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

logger "CloudWatch agent configuration completed"
USERDATA

  tags = {
    Name        = "harsh-ec2"
    Environment = "Lab"
  }
}

resource "aws_iam_user_policy_attachment" "cloudwatch_reader" {
  user       = "harsh.m.range@accenture.com"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}