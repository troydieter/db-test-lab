variable "aws-profile" {
  description = "AWS profile for provisioning the resources"
  type        = string
}

variable "aws_region" {
  description = "AWS Region- Defaulted to us-east-1"
  default     = "us-east-1"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "application" {
  description = "DB"
  type        = string
  default     = "data-lab"
}

variable "gateway_ip_address" {
  description = "IP Address of the File Storage Gateway Appliance"
  type        = string
}

variable "smb_guest_password" {
  description = "Password for the File Gateway File Share"
  type = string
  default = "majic123400"
}