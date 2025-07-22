provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "blog" {
  bucket = var.bucket_name
}

resource "aws_s3_object" "object1" {
  for_each     = fileset("html/", "*")
  bucket       = aws_s3_bucket.blog.id
  key          = each.value
  source       = "html/${each.value}"
  etag         = filemd5("html/${each.value}")
  content_type = "text/html"
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "whiz-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy attachment (S3 read access)
resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Instance profile used by EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "whiz-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Fetch available AZs
data "aws_availability_zones" "available" {}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Route Table Association for Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Public EC2 Instance
resource "aws_instance" "web" {
  ami                         = "ami-0cbbe2c6a1bb2ad63"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.web-sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = "tfkey"
  user_data_replace_on_change = true

  user_data = <<EOF
#!/bin/bash
yum update -y
yum install -y httpd aws-cli
aws s3 cp s3://${aws_s3_bucket.blog.bucket}/index.html /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF

  tags = {
    Name = "Whiz-EC2-Instance"
  }
}

resource "aws_security_group" "web-sg" {
  name        = "Web-SG"
  vpc_id      = aws_vpc.main.id
  description = "Security group for web server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
