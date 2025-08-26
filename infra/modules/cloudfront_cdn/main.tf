terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "origin_bucket_domain" { type = string }
variable "domain_name" { type = string }
variable "aliases" { type = list(string) }
variable "price_class" {
  type    = string
  default = "PriceClass_100"
}
variable "html_ttl_seconds" {
  type    = number
  default = 300
}
variable "asset_ttl_seconds" {
  type    = number
  default = 2592000
}
variable "acm_cert_arn" { type = string }
variable "use_default_cert" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_cloudfront_function" "security_headers" {
  name    = "security-headers-${replace(var.domain_name, ".", "-")}"
  runtime = "cloudfront-js-1.0"
  comment = "Add security headers to responses"
  publish = true
  code    = file("${path.module}/security-headers.js")
}

resource "aws_cloudfront_function" "url_rewrite" {
  name    = "url-rewrite-${replace(var.domain_name, ".", "-")}"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite URLs for directory-style routing"
  publish = true
  code    = file("${path.module}/url-rewrite.js")
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.domain_name}"
  description                       = "OAC for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.price_class
  aliases             = var.aliases
  default_root_object = "index.html"

  origin {
    domain_name              = var.origin_bucket_domain
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized

    default_ttl = var.asset_ttl_seconds
    max_ttl     = var.asset_ttl_seconds
    min_ttl     = 0

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.url_rewrite.arn
    }
    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  # Cache behavior for HTML files with shorter TTL
  ordered_cache_behavior {
    path_pattern           = "*.html"
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]

    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled

    default_ttl = var.html_ttl_seconds
    max_ttl     = var.html_ttl_seconds
    min_ttl     = 0

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.url_rewrite.arn
    }
    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.security_headers.arn
    }
  }

  # Handle directory-style URLs by trying index.html first
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/404.html"
  }
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.use_default_cert || length(var.acm_cert_arn) == 0 ? [1] : []
    content {
      cloudfront_default_certificate = true
      minimum_protocol_version       = "TLSv1.2_2021"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.use_default_cert || length(var.acm_cert_arn) == 0 ? [] : [1]
    content {
      acm_certificate_arn      = var.acm_cert_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }

  tags = var.tags
}

output "distribution_id" { value = aws_cloudfront_distribution.this.id }
output "distribution_domain" { value = aws_cloudfront_distribution.this.domain_name }
output "distribution_arn" { value = aws_cloudfront_distribution.this.arn }

