###############
# DMS Resources
###############

data "aws_iam_policy_document" "dms_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["dms.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "dms-access-for-endpoint" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-access-for-endpoint-${random_id.rando.hex}"
}

resource "aws_iam_role" "dms-cloudwatch-logs-role" {
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
  name               = "dms-cloudwatch-logs-role-${random_id.rando.hex}"
}

resource "aws_iam_role_policy_attachment" "dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
  role       = aws_iam_role.dms-cloudwatch-logs-role.name
}
resource "aws_iam_role" "dms-vpc-role" {
  name               = "dms-vpc-role"
  assume_role_policy = data.aws_iam_policy_document.dms_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dms-vpc-role-AmazonDMSVPCManagementRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
  role       = aws_iam_role.dms-vpc-role.name
  provisioner "local-exec" {
    command = "sleep 30"
  }
}

resource "aws_iam_role_policy_attachment" "dms-access-for-endpoint-AmazonDMSRedshiftS3Role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSRedshiftS3Role"
  role       = aws_iam_role.dms-vpc-role.name
}

# Create a new replication subnet group
resource "aws_dms_replication_subnet_group" "replsubnetgroup" {
  replication_subnet_group_description = "DMS replication subnet group"
  replication_subnet_group_id          = "dms-replication-subnet-group-${random_id.rando.hex}"

  subnet_ids = module.vpc.public_subnets
  depends_on = [
    aws_iam_role.dms-vpc-role,
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  ]

  tags = local.common-tags
}

module "dms_endpoint_s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "dms-endpoint-${random_id.rando.hex}"
  acl    = "private"

  versioning = {
    enabled = true
  }

  tags = local.common-tags

}

# IAM role and policy

resource "aws_iam_role" "dms_s3_role" {
  name        = "s3_dms_role-${random_id.rando.hex}"
  description = "Used for DMS endpoints"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "dms.amazonaws.com"
        }
      },
    ]
  })
  tags = local.common-tags
}

resource "aws_iam_policy" "dms_s3_pol" {
  name        = "s3_dms_s3_pol-${random_id.rando.hex}"
  description = "Used for DMS endpoint processing"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:ListBucket",
                "s3:ListBucketVersions",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "arn:aws:s3:::${module.dms_endpoint_s3_bucket.s3_bucket_id}",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::${module.dms_endpoint_s3_bucket.s3_bucket_id}/*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dms_s3_endpoint_attach" {
  role       = aws_iam_role.dms_s3_role.name
  policy_arn = aws_iam_policy.dms_s3_pol.arn
}

# DMS Replication Instance
resource "aws_dms_replication_instance" "replinstance" {
  allocated_storage          = 50
  apply_immediately          = true
  auto_minor_version_upgrade = true
  # engine_version             = "3.1.4"
  #   kms_key_arn                  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  multi_az                     = true
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible          = true
  replication_instance_class   = "dms.t3.micro"
  replication_instance_id      = "${var.application}-repl-instance-${random_id.rando.hex}"
  replication_subnet_group_id  = aws_dms_replication_subnet_group.replsubnetgroup.replication_subnet_group_id

  tags = {
    Name = "repl-${random_id.rando.hex}"
  }

  vpc_security_group_ids = [module.security_group.security_group_id]

  depends_on = [
    aws_iam_role_policy_attachment.dms-access-for-endpoint-AmazonDMSRedshiftS3Role,
    aws_iam_role_policy_attachment.dms-cloudwatch-logs-role-AmazonDMSCloudWatchLogsRole,
    aws_iam_role_policy_attachment.dms-vpc-role-AmazonDMSVPCManagementRole
  ]
}

# DMS Source Endpoint
resource "aws_dms_endpoint" "dbtestlab_source_endpoint" {
  endpoint_id                 = "${var.application}-endpoint-source-${random_id.rando.hex}"
  database_name               = "${var.dms_endpoint_dbname}-${random_id.rando.hex}"
  endpoint_type               = "source"
  engine_name                 = "sqlserver"
  extra_connection_attributes = ""
  password                    = module.db.db_instance_password
  port                        = module.db.db_instance_port
  server_name                 = module.db.db_instance_endpoint
  ssl_mode                    = "none"

  tags = local.common-tags

  username = module.db.db_instance_username
}

# DMS Destination Endpoint
resource "aws_dms_endpoint" "dbtestlab_dest_endpoint" {
  endpoint_id                 = "${var.application}-endpoint-dest-${random_id.rando.hex}"
  endpoint_type               = "target"
  engine_name                 = "s3"
  s3_settings {
    service_access_role_arn = aws_iam_role.dms_s3_role.arn
    bucket_name = module.dms_endpoint_s3_bucket.s3_bucket_id
    bucket_folder = "dms_dest"
    compression_type = "GZIP"
  }

  tags = local.common-tags

}

# Create a new replication task
resource "aws_dms_replication_task" "dbtestlab_repl_task" {
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.replinstance.replication_instance_arn
  replication_task_id       = "${var.application}-repl-task-${random_id.rando.hex}"
  source_endpoint_arn       = aws_dms_endpoint.dbtestlab_source_endpoint.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.dbtestlab_dest_endpoint.endpoint_arn
  table_mappings            = "{\"rules\":[{\"rule-type\":\"selection\",\"rule-id\":\"1\",\"rule-name\":\"1\",\"object-locator\":{\"schema-name\":\"%\",\"table-name\":\"%\"},\"rule-action\":\"include\"}]}"

  tags = local.common-tags
}