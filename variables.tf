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

variable "file_gw_activation_key" {
  description = "Activation Key retrieved from the Appliance"
  type = string
}