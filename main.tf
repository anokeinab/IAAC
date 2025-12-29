terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Example: allows any version in the 6.x series but prevents 7.x
    }
  }
}
provider "aws" {
  region     = "us-east-2"
  access_key = var.accesskey
  secret_key = var.secretkey
}

# Create a security group for admin instance
 resource "aws_security_group" "admin"{
  name = "admin-sg"
  description = "This is the security applied to the admin ec2 instance for ssh connexion"
  vpc_id = aws_vpc.vp_vpc.id

  # Ingress rule for SSH (port 22)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH from all IPv4 addresses
  }

  # Egress rule to allow all outbound traffic (default in AWS, but explicit in Terraform)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Represents all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_sg"
  }
 }

# Create backend security group without rules

resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "This is the backend security group"
  vpc_id      = aws_vpc.vp_vpc.id

   ingress {
    description     = "Security group to allow mysql connexion from admin security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.admin.id]
  }
}
# Create a self ingress rule for the backend sg to allow services in the backend to communication with eahc other
resource "aws_security_group_rule" "allow_self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1" # Allows all protocols
  security_group_id = aws_security_group.backend_sg.id
  self              = true # Allows traffic from instances within the same security group
  description       = "Allow all traffic from instances in the same security group"
}

# Create admin instance
resource "aws_instance" "admin" {
  ami                    = var.ami_ubuntu_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.admin.id]
  key_name               = var.key_name

  tags = {
    Name = "vprofile-adm"
  }

}
# Create parameter groups for rds instance

resource "aws_db_parameter_group" "vp_rds_pg" {
  name        = "vp-rds-pg"
  family      = "mysql8.0" # Or the appropriate family for your DB engine and version
  description = "Custom parameter group for my RDS instance"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name         = "max_connections"
    value        = "100"
    apply_method = "pending-reboot" # Some parameters require a reboot to apply
  }

  tags = {
    Environment = "Development"
    Project     = "MyApplication"
  }
}

# Create subnet groups for RDS
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.vp_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a" # Replace with your desired AZ
  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.vp_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b" # Replace with your desired AZ
  tags = {
    Name = "private-subnet-b"
  }
}

# Create db subnet group
resource "aws_db_subnet_group" "vp_rds_subnet_group" {
  name        = "vp-rds-subnet-group"
  description = "Subnet group for My RDS instance"
  subnet_ids = [
    aws_subnet.private_subnet_a.id,
    aws_subnet.private_subnet_b.id,
  ]
  tags = {
    Name = "vp-rds-subnet-group"
  }
}

# Create the RDS DB Instance
resource "aws_db_instance" "vp_rds" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0.39"      # Specify your desired version
  instance_class         = "db.t3.micro" # Choose an appropriate instance type
  identifier             = "vp-rds"
  username               = var.db_username
  password               = var.db_passw # Use a secure method for passwords in production
  parameter_group_name   = aws_db_parameter_group.vp_rds_pg.name
  db_subnet_group_name   = aws_db_subnet_group.vp_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  multi_az               = false # Enable Multi-AZ for high availability
  storage_type           = "gp3" # General Purpose SSD
  storage_encrypted      = true  # Enable encryption at rest
  #kms_key_id           = "alias/aws/rds" # Specify your KMS key or use default
  backup_retention_period = 7                     # Number of days to retain backups
  backup_window           = "03:00-04:00"         # Daily backup window
  maintenance_window      = "Mon:05:00-Mon:06:00" # Weekly maintenance window
  publicly_accessible     = false                 # Set to true if you need public access (not recommended for production)
  skip_final_snapshot     = true                  # Set to false in production to create a final snapshot
  apply_immediately       = true                  # Apply changes immediately
  deletion_protection     = false                 # Set to true in production to prevent accidental deletion
  #allow_major_version_upgrade = false # Set to true to allow major version upgrades
  #auto_minor_version_upgrade = true # Automatically apply minor version upgrades
  port                      = 3306
  db_name                   = "accounts"
  final_snapshot_identifier = "my-final-snapshot" # Required if skip_final_snapshot is false

  tags = {
    Name = "my-rds-instance"
  }
}

# Create Amazon MQ broker

resource "aws_mq_broker" "example_broker" {
  broker_name                = "my-rabbitmq-broker"
  engine_type                = "RABBITMQ"
  engine_version             = "3.13"
  auto_minor_version_upgrade = true
  host_instance_type         = "mq.t3.micro"
  security_groups            = [aws_security_group.backend_sg.id]
  subnet_ids                 = [aws_subnet.private_subnet_a.id]
  deployment_mode            = "SINGLE_INSTANCE"
  publicly_accessible        = false

  user {
    username = "rabbit"
    password = "BlueBunny9890"
  }

  tags = {
    Environment = "Development"
  }
}