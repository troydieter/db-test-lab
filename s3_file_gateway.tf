###############
# S3 File Gateway
# Download the OVA first https://d28e23pnuuv0hr.cloudfront.net/aws-storage-gateway-latest.ova
# Username: admin
# Password: password
# Install and retrieve the activation key FIRST
###############

resource "aws_storagegateway_gateway" "local_filegateway" {
  activation_key = var.file_gw_activation_key
  gateway_name       = "testlab-${random_id.rando.hex}"
  gateway_timezone   = "EST"
  gateway_type       = "FILE_S3"
}