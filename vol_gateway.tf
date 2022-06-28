###############
# S3 File Gateway
# Download the OVA first https://d28e23pnuuv0hr.cloudfront.net/aws-storage-gateway-latest.ova
# Username: admin
# Password: password
# Install and retrieve the IP address first - it is passed as gateway_ip_address
###############

# Cloudwatch Log Group
module "vol_gateway_log_group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "~> 3.0"

  name              = "testlab-log-group-${random_id.rando.hex}"
  retention_in_days = 120
}

resource "aws_storagegateway_gateway" "local_volgateway" {
  gateway_ip_address       = var.gateway_ip_address
  gateway_name             = "testlab-${random_id.rando.hex}"
  gateway_timezone         = "GMT-4:00"
  gateway_type             = "CACHED"
  cloudwatch_log_group_arn = module.vol_gateway_log_group.cloudwatch_log_group_arn
  smb_guest_password       = random_password.fileshare_pw.result
  tags                     = local.common-tags
}