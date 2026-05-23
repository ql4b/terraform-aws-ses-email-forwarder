data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  region      = data.aws_region.current.name
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = coalesce(var.bucket_name, "${module.this.id}-inbox")
  rule_set_name = coalesce(var.rule_set_name, "${module.this.id}-forwarder")
}
