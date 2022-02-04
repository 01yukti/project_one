#use modules for creating vpc
module "network" {
  source             = "../modules/vpc"
  vpc_id             = module.network.vpc_id
  aws_subnet_public  = module.network.aws_subnet_public
  aws_subnet_private = module.network.aws_subnet_private
}
