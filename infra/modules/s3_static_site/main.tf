terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "bucket_name" {
  type = string
}
variable "enable_logging" {
  type    = bool
  default = false
}
variable "distribution_arn" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "enable_cross_region_replication" {
  type    = bool
  default = false
  description = "Enable cross-region replication for disaster recovery"
}

resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
  force_destroy = false
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "noncurrent" {
  bucket = aws_s3_bucket.site.id
  rule {
    id     = "expire-noncurrent"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Allow only CloudFront OAC to access bucket when provided
data "aws_iam_policy_document" "bucket_policy" {
  count = length(var.distribution_arn) > 0 ? 1 : 0
  statement {
    sid    = "AllowCloudFrontOAC"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count  = length(var.distribution_arn) > 0 ? 1 : 0
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.bucket_policy[0].json
}

output "bucket_name" { value = aws_s3_bucket.site.bucket }

