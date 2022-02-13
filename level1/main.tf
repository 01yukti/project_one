#use modules for creating vpc
module "network" {
  source             = "../modules/vpc"
  vpc_id             = module.network.vpc_id
  aws_subnet_public  = module.network.aws_subnet_public
  aws_subnet_private = module.network.aws_subnet_private
}

resource "aws_route53_zone" "primary" {
  name = "yukti.click"

  tags = {
    Name = "primary"
  }
}

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
