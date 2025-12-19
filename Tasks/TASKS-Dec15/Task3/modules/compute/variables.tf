variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet for bastion host"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet for private instance"
  type        = string
}

variable "bastion_security_group_id" {
  description = "ID of the bastion security group"
  type        = string
}

variable "private_security_group_id" {
  description = "ID of the private security group"
  type        = string
}