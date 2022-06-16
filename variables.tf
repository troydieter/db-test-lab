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
  type        = string
  default     = "majic123400"
}

variable "active_directory_pw" {
  description = "Default password for Active Directory"
  type        = string
  default     = "maj!c8800!!"
}

variable "dms_endpoint_dbname" {
  description = "Database name used for the source DMS endpoint"
  type        = string
  default     = "labdb"
}