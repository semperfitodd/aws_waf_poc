

resource "aws_acm_certificate" "this" {
  domain_name       = local.site_domain
  validation_method = "DNS"

  tags = merge(var.tags,
    {
      Name = local.site_domain
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.site_domain
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
  }
}

resource "aws_route53_record" "verify" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}