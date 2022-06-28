###############
# S3 File Share
# Used in-conjunction with the file gateway
###############

# S3 Bucket creation for file share

module "volgw_dest_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "vol-gateway-share-${random_id.rando.hex}"
  acl    = "private"

  versioning = {
    enabled = true
  }

  tags = local.common-tags

}

# IAM role and policy

resource "aws_iam_role" "volgw_role" {
  name        = "s3_volgateway_role-${random_id.rando.hex}"
  description = "Used for S3 vol gateway fileshares"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "storagegateway.amazonaws.com"
        }
      },
    ]
  })
  tags = local.common-tags
}

resource "aws_iam_policy" "volgw_pol" {
  name        = "s3_filegateway_pol-${random_id.rando.hex}"
  description = "Used for S3 file gateway fileshares"
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
            "Resource": "arn:aws:s3:::${module.volgw_dest_bucket.s3_bucket_id}",
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
            "Resource": "arn:aws:s3:::${module.volgw_dest_bucket.s3_bucket_id}/*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "filegw_attach" {
  role       = aws_iam_role.volgw_role.name
  policy_arn = aws_iam_policy.volgw_pol.arn
}

# File Storage Gateway File Share

# resource "aws_storagegateway_smb_file_share" "local_volgateway_share" {
#   authentication        = "GUEST"
#   gateway_arn           = aws_storagegateway_gateway.local_volgateway.arn
#   location_arn          = module.volgw_dest_bucket.s3_bucket_arn
#   role_arn              = aws_iam_role.volgw_role.arn
#   audit_destination_arn = module.vol_share_log_group.cloudwatch_log_group_arn
#   tags                  = local.common-tags
#   depends_on = [
#     aws_storagegateway_gateway.local_volgateway
#   ]
# }

# # Audit logs for fileshare
# module "vol_share_log_group" {
#   source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
#   version = "~> 3.0"

#   name              = "testlab-log-group-fileshare-${random_id.rando.hex}"
#   retention_in_days = 30
# }