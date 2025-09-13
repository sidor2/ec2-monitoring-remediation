#!/bin/bash
# Update packages
yum update -y

# Install CloudWatch Agent and stress tool for testing
yum install -y amazon-cloudwatch-agent stress

# Write CloudWatch Agent config from Terraform-provided file
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
${file("${path.module}/cwagent-config.json")}
EOF

# Start CloudWatch Agent with that config
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# Enable service persistence
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent