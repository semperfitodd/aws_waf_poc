module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.6.0"

  name = local.environment

  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = module.vpc.public_subnets
  vpc_id          = module.vpc.vpc_id

  target_groups = [
    {
      name_prefix      = substr(local.environment, 0, 5)
      backend_protocol = "HTTP"
      backend_port     = local.port
      target_type      = "ip"
    }
  ]

  https_listeners = [
    {
      certificate_arn    = aws_acm_certificate.this.arn
      port               = 443
      protocol           = "HTTPS"
      ssl_policy         = "ELBSecurityPolicy-TLS-1-2-2017-01"
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = var.tags

  depends_on = [aws_acm_certificate.this]
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_host" {
  alarm_name          = "${var.environment}_unhealthy_host"
  alarm_description   = "Alarm showing unhealthy host in target group"
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 3
  evaluation_periods  = 3
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
    TargetGroup  = module.alb.target_group_arn_suffixes[0]
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "server_error_alarm" {
  alarm_name          = "${var.environment}_5XX"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "latency_alarm" {
  alarm_name          = "${var.environment}_TargetResponseTime"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    LoadBalancer = module.alb.lb_arn_suffix
  }

  alarm_description = "This metric monitors Target Response Time for ${var.environment} target group instances"
}

resource "aws_security_group" "alb" {
  name        = "${var.environment}_alb"
  description = "${var.environment} ALB security group"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "alb_egress" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Managed by Terraform"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.alb.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "alb_http" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Managed by Terraform"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "alb_https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Managed by Terraform"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  to_port           = 443
  type              = "ingress"
}