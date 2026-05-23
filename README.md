# terraform-aws-ses-email-forwarder

A minimal Terraform module for receiving email with Amazon SES and forwarding it to an existing mailbox.

This module is intended for small, domain-owned contact addresses where running a full mail server would be unnecessary overhead.

Examples:

- `hello@cloudless.sh`
- `contact@airos.sh`
- `support@example.com`

The goal is simple:

> Own the address. Don't run a mail server.

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
- Lambda function for forwarding (Node.js 22, ARM64)
- IAM permissions for SES, S3, and Lambda
- CloudWatch log group for the forwarder function

## Usage

```hcl

module "cloudless_email" {
  source = "git::https://github.com/ql4b/terraform-aws-ses-email-forwarder.git?ref=main"
  

  namespace = "cloudless"
  name      = "email"

  domain_name = "cloudless.sh"

  recipients = [
    "hello@cloudless.sh",
    "contact@cloudless.sh",
  ]

  forward_to = [
    "carlo@example.com",
  ]

  route53_zone_id = data.aws_route53_zone.cloudless.zone_id

  create_identity  = true
  create_mx_record = true

  message_retention_days = 30
}
```

This creates resources named with the prefix `cloudless-email`:

- `cloudless-email-inbox` (S3 bucket)
- `cloudless-email-forwarder` (Lambda function)
- `cloudless-email-forwarder` (SES receipt rule set)

## Existing SES identity

If the SES identity is managed elsewhere, for example with an existing SES module, identity creation can be disabled:

```hcl
module "airos_email" {
  source = "git::https://github.com/ql4b/terraform-aws-ses-email-forwarder.git?ref=main"

  namespace = "airos"
  name      = "email"

  domain_name = "airos.sh"

  recipients = [
    "contact@airos.sh",
  ]

  forward_to = [
    "carlo@example.com",
  ]

  route53_zone_id = data.aws_route53_zone.airos.zone_id

  create_identity  = false
  create_mx_record = true
}
```

## Context and naming

This module uses [cloudposse/label/null](https://github.com/cloudposse/terraform-null-label) for consistent resource naming and tagging.

All standard context variables are supported:

```hcl
module "email" {
  source = "git::https://github.com/ql4b/terraform-aws-ses-email-forwarder.git?ref=main"

  namespace   = "myorg"
  environment = "prod"
  name        = "email"
  attributes  = ["contact"]

  # ... module-specific variables
}
```

Resources will be named using the generated ID (e.g. `myorg-prod-email-contact-inbox`).

When composing with other modules that use the same labeling convention, pass context directly:

```hcl
module "email" {
  source = "git::https://github.com/ql4b/terraform-aws-ses-email-forwarder.git?ref=main"

  context = module.label.context

  domain_name = "example.com"
  recipients  = ["hello@example.com"]
  forward_to  = ["team@company.com"]

  route53_zone_id = data.aws_route53_zone.example.zone_id
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_forwarder"></a> [forwarder](#module\_forwarder) | git::https://github.com/ql4b/terraform-aws-lambda-function.git | v1.1.0 |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role_policy.forwarder](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_permission.ses](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.mx](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.ses_dkim](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.ses_verification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.inbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.inbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_policy.inbox](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_ses_active_receipt_rule_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_active_receipt_rule_set) | resource |
| [aws_ses_domain_dkim.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_dkim) | resource |
| [aws_ses_domain_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_domain_identity) | resource |
| [aws_ses_receipt_rule.forward](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule) | resource |
| [aws_ses_receipt_rule_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ses_receipt_rule_set) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Optional custom S3 bucket name for raw messages | `string` | `null` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "namespace": null,<br/>  "regex_replace_chars": null,<br/>  "stage": null,<br/>  "tags": {},<br/>  "tenant": null<br/>}</pre> | no |
| <a name="input_create_identity"></a> [create\_identity](#input\_create\_identity) | Whether to create the SES domain identity and DKIM records | `bool` | `true` | no |
| <a name="input_create_mx_record"></a> [create\_mx\_record](#input\_create\_mx\_record) | Whether to create the Route53 MX record for SES inbound receiving | `bool` | `true` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>   format = string<br/>   labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain used for inbound email receiving | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_forward_to"></a> [forward\_to](#input\_forward\_to) | Destination email addresses where messages are forwarded | `list(string)` | n/a | yes |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_message_retention_days"></a> [message\_retention\_days](#input\_message\_retention\_days) | Number of days to keep raw inbound messages in S3 | `number` | `30` | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_recipients"></a> [recipients](#input\_recipients) | Email addresses handled by the SES receipt rule | `list(string)` | n/a | yes |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_route53_zone_id"></a> [route53\_zone\_id](#input\_route53\_zone\_id) | Route53 hosted zone ID used to create DNS records | `string` | `null` | no |
| <a name="input_rule_set_name"></a> [rule\_set\_name](#input\_rule\_set\_name) | Optional SES receipt rule set name. If null, one is created | `string` | `null` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket storing raw inbound messages |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the S3 bucket storing raw inbound messages |
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | ARN of the Lambda forwarder function |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Name of the Lambda forwarder function |
| <a name="output_ses_domain_identity_arn"></a> [ses\_domain\_identity\_arn](#output\_ses\_domain\_identity\_arn) | ARN of the SES domain identity, when created by this module |
| <a name="output_ses_rule_set_name"></a> [ses\_rule\_set\_name](#output\_ses\_rule\_set\_name) | Name of the SES receipt rule set |
<!-- END_TF_DOCS -->

## Deployment

```bash
terraform apply
```

The Lambda binary is pre-compiled and shipped with the module. No build step required.

To rebuild from source (requires Go 1.23+):

```bash
make build
```

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

## SPF record

This module does not create an SPF TXT record because domains often have existing TXT records that would conflict.

For improved deliverability, add `include:amazonses.com` to your domain's SPF record manually:

```text
v=spf1 include:amazonses.com -all
```

If the domain already has a TXT record (e.g. Google site verification), merge the SPF value into the existing record set:

```text
"v=spf1 include:amazonses.com -all"
"google-site-verification=..."
```

SPF is not strictly required for forwarding — DKIM (created by this module when `create_identity = true`) is sufficient for most providers to accept the forwarded message.

## Message retention

Inbound messages are stored as raw email objects in S3 before they are forwarded.

By default, raw messages are retained for 30 days:

```hcl
message_retention_days = 30
```

Set this value according to the operational needs of the project. Short retention is usually enough for simple forwarding use cases.

## Dependencies

- [ql4b/terraform-aws-lambda-function](https://github.com/ql4b/terraform-aws-lambda-function) v1.1.0
- [cloudposse/label/null](https://github.com/cloudposse/terraform-null-label) >= 0.25.0
- Terraform >= 1.3
- AWS Provider >= 5.0

## Design philosophy

This module is intentionally small.

It does not try to provide a complete mail hosting solution. It only covers the narrow case of receiving email for a verified domain and forwarding it to an existing inbox.

That makes it useful for static websites, small products, documentation sites, internal tools, and lightweight project domains.

## License

MIT

