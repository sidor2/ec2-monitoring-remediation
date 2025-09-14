# Data source for the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 instance with CloudWatch Agent configuration
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_tokens   = "required"   # Enforces IMDSv2
    http_endpoint = "enabled"    # Metadata service must be enabled
  }

  user_data = <<-EOF
  #!/bin/bash
  set -e  # Exit on error

  # Update system
  echo "Running system update" >> /var/log/user-data.log
  sudo yum update -y || {
    echo "ERROR: Failed to update system" >> /var/log/user-data.log
    exit 1
  }

  # Install amazon-cloudwatch-agent
  echo "Installing amazon-cloudwatch-agent" >> /var/log/user-data.log
  sudo yum install -y amazon-cloudwatch-agent || {
    echo "ERROR: Failed to install amazon-cloudwatch-agent" >> /var/log/user-data.log
    exit 1
  }

  # Ensure CloudWatch Agent config directory exists
  mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
  chmod 755 /opt/aws/amazon-cloudwatch-agent/etc

  # Write CloudWatch Agent configuration and log for debugging
  echo "Writing CloudWatch Agent configuration to /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json" >> /var/log/user-data.log
  cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CONFIG'
  {
    "agent": {
      "metrics_collection_interval": 60,
      "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
    },
    "metrics": {
      "namespace": "CustomEC2Metrics",
      "metrics_collected": {
        "cpu": {
          "measurement": [
            "cpu_usage_idle",
            "cpu_usage_iowait",
            "cpu_usage_user",
            "cpu_usage_system"
          ],
          "totalcpu": true,
          "metrics_collection_interval": 60
        },
        "mem": {
          "measurement": [
            "mem_used",
            "mem_cached",
            "mem_total"
          ],
          "metrics_collection_interval": 60
        }
      }
    },
    "logs": {
      "logs_collected": {
        "files": {
          "collect_list": [
            {
              "file_path": "/var/log/messages",
              "log_group_name": "ec2-messages",
              "log_stream_name": "{instance_id}"
            }
          ]
        }
      }
    }
  }
  CONFIG

  # Verify the config file was created
  if [ -f /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json ]; then
    echo "Config file created successfully" >> /var/log/user-data.log
    cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json >> /var/log/user-data.log
  else
    echo "ERROR: Config file not created" >> /var/log/user-data.log
    exit 1
  fi

  # Start CloudWatch Agent
  echo "Starting CloudWatch Agent" >> /var/log/user-data.log
  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s || { echo "ERROR: Failed to start CloudWatch Agent" >> /var/log/user-data.log; exit 1; }

  # Enable and restart CloudWatch Agent
  systemctl enable amazon-cloudwatch-agent
  systemctl restart amazon-cloudwatch-agent

  # Log CloudWatch Agent status
  systemctl status amazon-cloudwatch-agent >> /var/log/user-data.log 2>&1

  # install stress test
  sudo amazon-linux-extras install epel -y
  sudo yum install -y stress
  EOF

  tags = {
    Project = "${var.proj_name}-instance"
  }
}