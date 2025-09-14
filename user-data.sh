#!/bin/bash
set -e  # Exit on error
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# Update system
echo "Running system update"
sudo yum update -y || { echo "ERROR: Failed to update system"; exit 1; }

# Install amazon-cloudwatch-agent
echo "Installing amazon-cloudwatch-agent"
sudo yum install amazon-cloudwatch-agent -y || { echo "ERROR: Failed to install amazon-cloudwatch-agent"; exit 1; }

# Ensure CloudWatch Agent config directory exists
echo "Creating config directory"
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
sudo chmod 755 /opt/aws/amazon-cloudwatch-agent/etc

# Write CloudWatch Agent configuration
echo "Writing CloudWatch Agent configuration"
sudo bash -c 'cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json' << 'CONFIG'
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
    },
    # "append_dimensions": {
    #   "Hostname": "${aws:Hostname}",
    #   "cpu": "cpu-total",
    #   "InstanceId": "${aws:InstanceId}",
    #   "Project": "monitoring-demo-instance"
    # }
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

# Verify the config file
if [ -f /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json ]; then
  echo "Config file created successfully"
  cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
else
  echo "ERROR: Config file not created"
  exit 1
fi

# Start CloudWatch Agent and capture output
echo "Starting CloudWatch Agent"
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s || { echo "ERROR: Failed to start CloudWatch Agent"; cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log; exit 1; }

# Enable and restart CloudWatch Agent
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl restart amazon-cloudwatch-agent

# Log CloudWatch Agent status
echo "Checking CloudWatch Agent status"
sudo systemctl status amazon-cloudwatch-agent >> /var/log/user-data.log 2>&1

# Install stress test
echo "Installing stress tool"
sudo amazon-linux-extras install -y epel
sudo yum install -y stress