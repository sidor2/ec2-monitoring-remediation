#!/bin/bash
yum update -y
yum install -y amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent