resource "aws_lb" "app" {
  count              = var.enabled ? 1 : 0
  name               = "${var.name_prefix}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  tags = {
    Name = "${var.name_prefix}-ALB"
  }
}

resource "aws_lb_target_group" "django" {
  count       = var.enabled ? 1 : 0
  name        = "${var.name_prefix}-TG-DJANGO"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTPS"
    port                = "443"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.name_prefix}-TG-DJANGO"
  }
}

resource "aws_lb_listener" "https" {
  count             = var.enabled ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django[0].arn
  }
}

resource "aws_lb_target_group_attachment" "django_proxy_attachment_azp" {
  target_group_arn = aws_lb_target_group.django[0].arn
  target_id        = var.az_primary_target_instance_id
  port             = 443
}

resource "aws_lb_target_group_attachment" "django_proxy_attachment_azs" {
  target_group_arn = aws_lb_target_group.django[0].arn
  target_id        = var.az_secondary_target_instance_id
  port             = 443
}

data "aws_route53_zone" "main" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "app_dns_cname" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.app_dns_cname
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.app[0].dns_name]
}
