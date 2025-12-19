variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for Amazon Linux 2023"
  default     = "ami-0199d4b5b8b4fde0e"
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair"
  type        = string
  default     = "hp-envy-home"
}

variable "ami_ubuntu_id" {
  description = "AMI ID for Ubuntu 24"
  default     = "ami-0cfde0ea8edd312d4"
}

variable "accesskey"{
    description = "access key"
    type = string
    sensitive = true
}

variable "secretkey"{
    description = "secret key"
    type = string
    sensitive = true
}