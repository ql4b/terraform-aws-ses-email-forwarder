# terraform-aws-ses-email-forwarder


# terraform-aws-ses-email-forwarder

A minimal Terraform module for receiving email with Amazon SES and forwarding it to an existing mailbox.

This module is intended for small, domain-owned contact addresses where running a full mail server would be unnecessary overhead.

Examples:

- `hello@cloudless.sh`
- `contact@airos.sh`
- `support@example.com`

The goal is simple:

> Own the address. Don’t run a mail server.

## Architecture

```text
Internet
   ↓
Amazon SES inbound receiving
   ↓
SES receipt rule
   ↓
S3 bucket storing the raw message
   ↓
Lambda forwarder
   ↓
Existing destination mailbox
```

Amazon SES does not pass the full raw email body directly to a Lambda receipt action. For forwarding use cases, the usual pattern is to store the inbound message in S3 first, then let Lambda read the raw message from S3 and forward it.

## Use cases

Use this module when you want to publish an email address for a project, domain, product, or internal tool, but you do not want to operate a mailbox provider for that domain.

Good examples:

- a contact address for a static website
- a project inbox forwarded to an existing company mailbox
- lightweight inbound email for documentation, demos, or small services
- domain-specific aliases that forward to one or more real inboxes

This module is not intended to be a full email platform.

## What it creates

Depending on configuration, the module can create:

- SES domain identity
- SES DKIM DNS records
- Route53 MX record for SES inbound receiving
- SES receipt rule set
- SES receipt rule for one or more recipients
- S3 bucket for raw inbound messages
- S3 lifecycle policy for message retention
- Lambda function for forwarding
- IAM permissions for SES, S3, and Lambda

## Usage

```hcl
module "cloudless_email" {
  source = "github.com/ql4b/terraform-aws-ses-email-forwarder"

  domain_name = "cloudless.sh"

  recipients = [
    "hello@cloudless.sh",
    "contact@cloudless.sh",
  ]

  forward_to = [
    "carlo@ql4b.com",
  ]

  route53_zone_id = data.aws_route53_zone.cloudless.zone_id

  create_identity  = true
  create_mx_record = true

  message_retention_days = 30
}
```

## Existing SES identity

If the SES identity is managed elsewhere, for example with an existing SES module, identity creation can be disabled:

```hcl
module "airos_email" {
  source = "github.com/ql4b/terraform-aws-ses-email-forwarder"

  domain_name = "airos.sh"

  recipients = [
    "contact@airos.sh",
  ]

  forward_to = [
    "carlo@ql4b.com",
  ]

  route53_zone_id = data.aws_route53_zone.airos.zone_id

  create_identity = false
  create_mx_record = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `domain_name` | Domain used for inbound email receiving. | `string` | n/a | yes |
| `recipients` | Email addresses handled by the SES receipt rule. | `list(string)` | n/a | yes |
| `forward_to` | Destination email addresses where messages are forwarded. | `list(string)` | n/a | yes |
| `route53_zone_id` | Route53 hosted zone ID used to create DNS records. | `string` | `null` | no |
| `create_identity` | Whether to create the SES domain identity. | `bool` | `true` | no |
| `create_mx_record` | Whether to create the Route53 MX record for SES inbound receiving. | `bool` | `true` | no |
| `message_retention_days` | Number of days to keep raw inbound messages in S3. | `number` | `30` | no |
| `bucket_name` | Optional custom S3 bucket name for raw messages. | `string` | `null` | no |
| `rule_set_name` | Optional SES receipt rule set name. | `string` | `null` | no |
| `tags` | Tags applied to supported resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `bucket_name` | Name of the S3 bucket storing raw inbound messages. |
| `bucket_arn` | ARN of the S3 bucket storing raw inbound messages. |
| `lambda_function_name` | Name of the Lambda forwarder function. |
| `lambda_function_arn` | ARN of the Lambda forwarder function. |
| `ses_rule_set_name` | Name of the SES receipt rule set. |
| `ses_domain_identity_arn` | ARN of the SES domain identity, when created by this module. |

## SES receiving region

Amazon SES inbound email receiving is only available in selected AWS regions. Deploy this module in a region that supports SES receiving and make sure the MX record points to the corresponding inbound endpoint.

Example MX value:

```text
10 inbound-smtp.eu-west-1.amazonaws.com
```

## DNS requirements

For receiving email through SES, the domain needs an MX record pointing to the SES inbound endpoint.

If `create_mx_record = true`, the module can create that record in Route53.

If DNS is managed elsewhere, set `create_mx_record = false` and create the MX record manually.

## Message retention

Inbound messages are stored as raw email objects in S3 before they are forwarded.

By default, raw messages are retained for 30 days:

```hcl
message_retention_days = 30
```

Set this value according to the operational needs of the project. Short retention is usually enough for simple forwarding use cases.

## Design philosophy

This module is intentionally small.

It does not try to provide a complete mail hosting solution. It only covers the narrow case of receiving email for a verified domain and forwarding it to an existing inbox.

That makes it useful for static websites, small products, documentation sites, internal tools, and lightweight project domains.

## License

MIT