###############
# S3 File Gateway
# Download the OVA first https://d28e23pnuuv0hr.cloudfront.net/aws-storage-gateway-latest.ova
# Username: admin
# Password: password
# Install and retrieve the IP address first - it is passed as gateway_ip_address
###############

# Cloudwatch Log Group
module "log_group" "file_storage_gateway_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 3.0"

  name              = "testlab-log-group-${random_id.rando.hex}"
  retention_in_days = 120
}

resource "aws_storagegateway_gateway" "local_filegateway" {
  gateway_ip_address = var.gateway_ip_address
  gateway_name       = "testlab-${random_id.rando.hex}"
  gateway_timezone   = "GMT-4:00"
  gateway_type       = "FILE_S3"
  cloudwatch_log_group_arn = module.log_group.file_storage_gateway_log_group.cloudwatch_log_group_arn
  smb_guest_password = var.smb_guest_password
  tags = local.common-tags
}