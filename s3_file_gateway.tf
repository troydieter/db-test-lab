###############
# S3 File Gateway
# Download the OVA first https://d28e23pnuuv0hr.cloudfront.net/aws-storage-gateway-latest.ova
# Username: admin
# Password: password
# Install and retrieve the IP address first - it is passed as gateway_ip_address
###############

resource "aws_storagegateway_gateway" "local_filegateway" {
  gateway_ip_address = var.gateway_ip_address
  gateway_name       = "testlab-${random_id.rando.hex}"
  gateway_timezone   = "GMT-4:00"
  gateway_type       = "FILE_S3"
}