################################################################################
# AWS Directory Service (Acitve Directory)
################################################################################

resource "aws_directory_service_directory" "testlab" {
  name     = "corp.dbtestlab.com"
  password = var.active_directory_pw
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id = module.vpc.vpc_id
    # Only 2 subnets, must be in different AZs
    subnet_ids = slice(tolist(module.vpc.database_subnets), 0, 2)
  }

  tags = local.common-tags
}

################################################################################
# IAM Role for Windows Authentication
################################################################################

data "aws_iam_policy_document" "rds_assume_role" {
  statement {
    sid = "AssumeRole"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_ad_auth" {
  name                  = "rdstestlab-rds-ad-auth-${random_id.rando.hex}"
  description           = "Role used by RDS for Active Directory authentication and authorization"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.rds_assume_role.json

  tags = local.common-tags
}

resource "aws_iam_role_policy_attachment" "rds_directory_services" {
  role       = aws_iam_role.rds_ad_auth.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSDirectoryServiceAccess"
}

###############
# RDS Source Resources
###############


module "db" {

  source  = "terraform-aws-modules/rds/aws"
  version = "4.2.0"

  identifier = "dbtestlabrds${random_id.rando.hex}"
  engine               = "sqlserver-ex"
  engine_version       = "15.00.4153.1.v1"
  family               = "sqlserver-ex-15.0" # DB parameter group
  major_engine_version = "15.00"             # DB option group
  instance_class       = "db.t3.small"

  allocated_storage     = 20
  max_allocated_storage = 100

  username = "dblabs_user"
  port     = 1433

  multi_az                        = false
  subnet_ids                      = module.vpc.database_subnets
  vpc_security_group_ids          = [module.security_group.security_group_id]
  license_model                   = "license-included"
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["error"]
  create_cloudwatch_log_group     = true
  db_subnet_group_name            = module.vpc.database_subnet_group_name
  create_db_option_group          = false
  create_db_parameter_group       = false
  domain                          = aws_directory_service_directory.testlab.id
  domain_iam_role_name            = aws_iam_role.rds_ad_auth.name
  storage_encrypted               = false

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = false
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "${var.application}-rds-mon-${random_id.rando.hex}"
  create_random_password                = true

  tags = local.common-tags
  db_instance_tags = {
    "Sensitive" = "high"
  }
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
}