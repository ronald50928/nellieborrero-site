terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" { region = "us-east-1" }

variable "domain_name" {
  type    = string
  default = "nellieborrero.com"
}
variable "enable_logging" {
  type    = bool
  default = false
}
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
variable "project" {
  type    = string
  default = "nellieborrero-site"
}
locals {
  tags = {
    Project   = var.project
    ManagedBy = "terraform"
    Env       = "prod"
  }
}

module "s3" {
  source         = "../../modules/s3_static_site"
  bucket_name    = "${var.project}-${random_id.suffix.hex}"
  enable_logging = var.enable_logging
  tags           = local.tags
  distribution_arn = module.cdn.distribution_arn
  # oac_iam_arn set after CloudFront created (2-step apply not needed if we allow public read via OAC policy only). We'll update after CF create.
}

# ACM would be created/validated separately; placeholder input expected
variable "acm_cert_arn" { type = string }

module "cdn" {
  source              = "../../modules/cloudfront_cdn"
  origin_bucket_domain = "${module.s3.bucket_name}.s3.amazonaws.com"
  domain_name         = var.domain_name
  aliases             = ["nellieborrero.com", "www.nellieborrero.com"]
  price_class         = var.price_class
  html_ttl_seconds    = var.html_ttl_seconds
  asset_ttl_seconds   = var.asset_ttl_seconds
  acm_cert_arn        = "arn:aws:acm:us-east-1:796973484720:certificate/e8b0876e-9d34-4d01-8dd6-5ffc301e9335"
  use_default_cert    = false
  tags                = local.tags
}

module "dns" {
  source     = "../../modules/route53_dns"
  domain_name = var.domain_name
  cf_domain   = module.cdn.distribution_domain
  cf_zone_id  = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID
}

module "oidc" {
  source = "../../modules/iam_oidc_github"
  repo   = "ronald50928/nellieborrero-site"
  bucket_arn = "arn:aws:s3:::${module.s3.bucket_name}"
  distribution_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.cdn.distribution_id}"
}

output "bucket" { value = module.s3.bucket_name }
output "distribution_domain" { value = module.cdn.distribution_domain }
output "distribution_id" { value = module.cdn.distribution_id }
output "deploy_role_arn" { value = module.oidc.deploy_role_arn }
output "route53_nameservers" { value = module.dns.nameservers }
output "route53_hosted_zone_id" { value = module.dns.hosted_zone_id }
data "aws_caller_identity" "current" {}

resource "random_id" "suffix" { byte_length = 4 }

