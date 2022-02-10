#use modules for database
module "database" {
  source             = "../modules/database"
  vpc_id             = module.network.vpc_id
  aws_subnet_public  = module.network.aws_subnet_public
  aws_subnet_private = module.network.aws_subnet_private
  security_groups    = module.instances.security_groups
}

