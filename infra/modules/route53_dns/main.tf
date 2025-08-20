terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "domain_name" { type = string }
variable "cf_domain" { type = string }
variable "cf_zone_id" { type = string }

resource "aws_route53_zone" "this" {
  name = var.domain_name
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = var.cf_domain
    zone_id                = var.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "AAAA"
  alias {
    name                   = var.cf_domain
    zone_id                = var.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  alias {
    name                   = var.cf_domain
    zone_id                = var.cf_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"
  alias {
    name                   = var.cf_domain
    zone_id                = var.cf_zone_id
    evaluate_target_health = false
  }
}

# Email DNS Records for Microsoft/Outlook Email
# Combined TXT Records (domain verification + SPF)
resource "aws_route53_record" "email_txt_combined" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300
  records = [
    "MS=ms16567308",
    "v=spf1 include:secureserver.net -all"
  ]
}

# CNAME Records for email services
resource "aws_route53_record" "email_autodiscover" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "autodiscover.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["autodiscover.outlook.com"]
}

resource "aws_route53_record" "email_cname" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "email.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["email.secureserver.net"]
}

# MX Record for mail routing
resource "aws_route53_record" "email_mx" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 300
  records = ["0 nellieborrero-com.mail.protection.outlook.com"]
}

output "hosted_zone_id" { value = aws_route53_zone.this.zone_id }
output "nameservers" { value = aws_route53_zone.this.name_servers }

