#use modules for load balancer
module "loadbalancer" {
  source               = "../modules/alb"
  vpc_id               = module.network.vpc_id
  autoscaling_grp_name = module.instances.autoscaling_grp_name
  aws_subnet_public    = module.network.aws_subnet_public
  aws_subnet_private   = module.network.aws_subnet_private
  target_group_arn     = module.loadbalancer.target_group_arn
}
