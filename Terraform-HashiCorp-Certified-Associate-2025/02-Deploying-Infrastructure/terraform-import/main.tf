terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "imported_server" {
  # Minimal stub for import
  ami           = "i-07b8575e217c13c90"   # placeholder, will be updated
  instance_type = "t3.micro"       # placeholder
}