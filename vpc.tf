###############
# VPC Resources
###############

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.application}-vpc-${random_id.rando.hex}"
  cidr = "10.77.0.0/18"

  azs              = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnets   = ["10.77.0.0/24", "10.77.1.0/24", "10.77.2.0/24"]
  private_subnets  = ["10.77.3.0/24", "10.77.4.0/24", "10.77.5.0/24"]
  database_subnets = ["10.77.7.0/24", "10.77.8.0/24", "10.77.9.0/24"]

  create_database_subnet_group = true

  tags = local.common-tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.application}-sg-rds-${random_id.rando.hex}"
  description = "SG for RDS ${random_id.rando.hex}"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MSSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.common-tags
}