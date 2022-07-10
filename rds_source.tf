###############
# RDS Source Resources
###############


module "db" {

  source  = "terraform-aws-modules/rds/aws"
  version = "4.3.0"

  identifier           = "dbtestlabrds${random_id.rando.hex}"
  engine               = "mysql"
  engine_version       = "8.0.27"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t3.small"
  db_name = "dbtestlab-${random_id.rando.hex}"

  allocated_storage     = 20
  max_allocated_storage = 100

  username = "dblabs_user"
  port     = 3306

  multi_az                        = false
  subnet_ids                      = module.vpc.database_subnets
  vpc_security_group_ids          = [module.security_group.security_group_id]
  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["error"]
  create_cloudwatch_log_group     = false
  db_subnet_group_name            = module.vpc.database_subnet_group_name
  create_db_option_group          = false
  create_db_parameter_group       = false
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

output "db_address" {
  description = "The RDS source address"
  value = module.db.db_instance_address
}

output "db_username" {
  description = "The RDS source username"
  value = module.db.db_instance_username
  sensitive = true
}

output "db_password" {
  description = "The RDS source password"
  value = module.db.db_instance_password
  sensitive = true
}

output "db_name" {
  description = "The name of the database"
  value = module.db.db_instance_name
}