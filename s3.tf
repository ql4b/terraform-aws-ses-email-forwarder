resource "aws_s3_bucket" "inbox" {
  bucket = local.bucket_name
  tags   = module.this.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "inbox" {
  bucket = aws_s3_bucket.inbox.id

  rule {
    id     = "expire-messages"
    status = "Enabled"

    filter {}

    expiration {
      days = var.message_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "inbox" {
  bucket = aws_s3_bucket.inbox.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ses.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.inbox.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceAccount" = local.account_id
        }
      }
    }]
  })
}
