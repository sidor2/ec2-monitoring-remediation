resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Open for SSH brute force testing
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "isolation_sg" {
  vpc_id = aws_vpc.main.id

  # No ingress rules (implicit deny all inbound)
  # Default egress allow all, but combined with isolation route table, outbound is blocked at network level

  tags = {
    Name = "isolation-sg"
  }
}