#configure security group
resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  #vpc_id = aws_vpc.example.id
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

#Configure application load balancer
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  #subnets            = [for subnet in var.aws_subnet_public : subnet.id]
  subnets = [var.aws_subnet_public[0],var.aws_subnet_public[1]]
  tags = {
    Name = "custom-alb"
  }
}

#configure listener
resource "aws_alb_listener" "frontend" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn = aws_acm_certificate_validation.alb_cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.albtg.arn
  }

  tags = {
    Name = "listener-frontend"
  }
}

#create target groups
resource "aws_alb_target_group" "albtg" {
  name     = "albtg"
  port     = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    port     = 80
    protocol = "HTTP"
    timeout  = 6
    interval = 10
  }

  tags = {
    Name = "target_group"
  }
}

output "target_group_arn" {
    value = aws_alb_target_group.albtg.arn
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_tg_attach" {
  autoscaling_group_name = var.autoscaling_grp_name
  alb_target_group_arn   = var.target_group_arn
}

#create a route53 zone
resource "aws_route53_zone" "primary" {
  name = "yukti.click"

  tags = {
    Name = "primary"
  }
}

#create a record under route53
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.yukti.click"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

#create a cert
resource "aws_acm_certificate" "alb_cert" {
  domain_name       = "yukti.click"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
} 

resource "aws_route53_record" "val_cert" {
  for_each = {
    for dvo in aws_acm_certificate.alb_cert.domain_validation_options : dvo.domain_name => {
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
  zone_id         = aws_route53_zone.primary.zone_id
}

#validate cert
resource "aws_acm_certificate_validation" "alb_cert" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.val_cert : record.fqdn]
}
