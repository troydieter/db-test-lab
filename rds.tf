###############
# RDS Resources
###############

module "db" {

  source  = "terraform-aws-modules/rds/aws"
  version = "4.2.0"

  identifier = "${var.application}-rds-${random_id.rando.hex}"

  engine               = "sqlserver-ex"
  engine_version       = "15.00.4153.1.v1"
  family               = "sqlserver-ex-15.0" # DB parameter group
  major_engine_version = "15.00"      # DB option group
  instance_class       = "db.t3.large"

  allocated_storage     = 20
  max_allocated_storage = 100

  domain               = aws_directory_service_directory.demo.id
  domain_iam_role_name = aws_iam_role.rds_ad_auth.name
  
  username = "${var.application}_dbuser"
  port     = 3306

  multi_az               = true
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.security_group.security_group_id]
  license_model             = "license-included"
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]
  create_cloudwatch_log_group     = true
  db_subnet_group_name            = module.vpc.database_subnet_group_name

  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "${var.application}-rds-mon-${random_id.rando.hex}"
  create_random_password                = true

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

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