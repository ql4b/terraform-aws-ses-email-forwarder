# Domain Identity
resource "aws_ses_domain_identity" "this" {
  count  = var.create_identity ? 1 : 0
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "this" {
  count  = var.create_identity ? 1 : 0
  domain = aws_ses_domain_identity.this[0].domain
}

resource "aws_route53_record" "ses_verification" {
  count   = var.create_identity && var.route53_zone_id != null ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "_amazonses.${var.domain_name}"
  type    = "TXT"
  ttl     = 1800
  records = [aws_ses_domain_identity.this[0].verification_token]
}

resource "aws_route53_record" "ses_dkim" {
  count   = var.create_identity && var.route53_zone_id != null ? 3 : 0
  zone_id = var.route53_zone_id
  name    = "${aws_ses_domain_dkim.this[0].dkim_tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 1800
  records = ["${aws_ses_domain_dkim.this[0].dkim_tokens[count.index]}.dkim.amazonses.com"]
}



# Receipt Rule Set
resource "aws_ses_receipt_rule_set" "this" {
  rule_set_name = local.rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "this" {
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
}

# Receipt Rule: store in S3 then invoke Lambda forwarder
resource "aws_ses_receipt_rule" "forward" {
  name          = "${module.this.id}-forward"
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
  recipients    = var.recipients
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name = aws_s3_bucket.inbox.id
    position    = 1
  }

  lambda_action {
    function_arn    = module.forwarder.function_arn
    invocation_type = "Event"
    position        = 2
  }

  depends_on = [
    aws_s3_bucket_policy.inbox,
    aws_lambda_permission.ses
  ]
}
