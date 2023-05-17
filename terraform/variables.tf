variable "environment" {
  description = "Environment name for project"
  type        = string

  default = "aws_waf_poc"
}

variable "public_domain" {
  description = "Public DNS zone name"
  type        = string

  default = "bsisandbox.com"
}

variable "region" {
  description = "AWS Region where resources will be deployed"
  type        = string

  default = "us-east-2"
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)

  default = {}
}