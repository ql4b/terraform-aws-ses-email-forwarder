module "forwarder" {
  source = "git::https://github.com/ql4b/terraform-aws-lambda-function.git?ref=v1.1.0"

  context    = module.this.context
  attributes = ["forwarder"]

  source_dir = "${path.module}/src"
  handler    = "forwarder.handler"
  runtime    = "nodejs22.x"
  timeout    = 30

  environment_variables = {
    S3_BUCKET  = aws_s3_bucket.inbox.id
    FORWARD_TO = join(",", var.forward_to)
    FROM_EMAIL = "noreply@${var.domain_name}"
  }
}

resource "aws_lambda_permission" "ses" {
  statement_id   = "AllowSES"
  action         = "lambda:InvokeFunction"
  function_name  = module.forwarder.function_name
  principal      = "ses.amazonaws.com"
  source_account = local.account_id
}

resource "aws_iam_role_policy" "forwarder" {
  name = "ses-forwarder"
  role = module.forwarder.execution_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.inbox.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "ses:SendRawEmail"
        Resource = "*"
      }
    ]
  })
}
