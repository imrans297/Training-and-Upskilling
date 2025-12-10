# main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-03f9680ef0c07a3d1"
  instance_type = "t2.micro"
  
  tags = {
    Name = "WebServer-${count.index}"
  }
}

resource "aws_s3_bucket" "data" {
  bucket = "my-state-lab-bucket-${random_id.suffix.hex}"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "manual" {
  bucket = "my-manual-bucket-1234"
}

output "instance_id" {
  value = aws_instance.web[0].id
}

