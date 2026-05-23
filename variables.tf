variable "domain_name" {
  type        = string
  description = "Domain used for inbound email receiving"
}

variable "recipients" {
  type        = list(string)
  description = "Email addresses handled by the SES receipt rule"
}

variable "forward_to" {
  type        = list(string)
  description = "Destination email addresses where messages are forwarded"
}

variable "route53_zone_id" {
  type        = string
  default     = null
  description = "Route53 hosted zone ID used to create DNS records"
}

variable "create_identity" {
  type        = bool
  default     = true
  description = "Whether to create the SES domain identity and DKIM records"
}

variable "create_mx_record" {
  type        = bool
  default     = true
  description = "Whether to create the Route53 MX record for SES inbound receiving"
}

variable "message_retention_days" {
  type        = number
  default     = 30
  description = "Number of days to keep raw inbound messages in S3"
}

variable "bucket_name" {
  type        = string
  default     = null
  description = "Optional custom S3 bucket name for raw messages"
}

variable "rule_set_name" {
  type        = string
  default     = null
  description = "Optional SES receipt rule set name. If null, one is created"
}


