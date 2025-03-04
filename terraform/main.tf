# Define the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Define a variable for the SSH public key
variable "ssh_public_key" {}

# Create an AWS Key Pair using the SSH public key from GitHub Secrets
resource "aws_key_pair" "web_key" {
  key_name   = "web-app-key"
  public_key = var.ssh_public_key
}

# Create a Security Group to allow SSH and HTTP access
resource "aws_security_group" "web_sg" {
  name        = "web-app-sg"
  description = "Allow HTTP and SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (use with caution)
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access to web app (if running on 8080)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 Instance
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.web_key.key_name
  security_groups = [aws_security_group.web_sg.name]

  # User data script to install Docker and run the container
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install docker -y
              sudo service docker start
              sudo usermod -aG docker ec2-user
              sudo docker run -d -p 80:80 thaworapong/testing:latest
              EOF

  tags = {
    Name = "WebAppServer"
  }
}

# Output the instance's public IP
output "instance_ip" {
  value = aws_instance.web_server.public_ip
}
