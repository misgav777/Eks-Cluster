# Purpose: Define the variables that will be used in the EKS module

variable "env" {
  type = string
}

variable "project_name" {
  type = string
}

# VPC variables
variable "region" {
  type = string
}

variable "vpc_cider_block" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

# EKS variables
variable "eks_name" {
  type = string
}

variable "eks_version" {
  type = string
}


# EC2 instance variables
variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}