#configure aws provider
provider "aws" {
  region  = var.region
  profile = "student-user"
}

# Create VPC
module "vpc" {
  source                       = "../modules/VPC"
  region                       = var.region
  project_name                 = var.project_name
  vpc_cidr                     = var.vpc_cidr
  public_subnet_az1_cidr       = var.public_subnet_az1_cidr
  public_subnet_az2_cidr       = var.public_subnet_az2_cidr
  private_app_subnet_az1_cidr  = var.private_app_subnet_az1_cidr
  private_app_subnet_az2_cidr  = var.private_app_subnet_az2_cidr
  private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
  private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr
}

# Create NATGW
module "nat_gateway" {
  source                     = "../modules/NAT-GW"
  project_name               = module.vpc.project_name
  vpc_id                     = module.vpc.vpc_id
  public_subnet_az1_id       = module.vpc.public_subnet_az1_id
  public_subnet_az2_id       = module.vpc.public_subnet_az2_id
  internet_gateway           = module.vpc.internet_gateway
  private_app_subnet_az1_id  = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id  = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az1_id = module.vpc.private_data_subnet_az1_id
  private_data_subnet_az2_id = module.vpc.private_data_subnet_az2_id

}

# Create SG
module "security_groups" {
  source       = "../modules/SG"
  vpc_id       = module.vpc.vpc_id
  project_name = module.vpc.project_name
}

# Create ecs task EX role
module "ecs_tasks_execution_role" {
  source       = "../modules/ECS-TASK-EX-ROLE"
  project_name = module.vpc.project_name
}

# Create ACM Variables
module "acm" {
  source          = "../modules/ACM"
  domain_name     = var.domain_name
  sub_domain_name = var.sub_domain_name
}

# Create ALB 
module "application_load_balancer" {
  source                = "../modules/ALB"
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security_groups.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  vpc_id                = module.vpc.vpc_id
  certificate_arn       = module.acm.certificate_arn
}

# Create ECS
module "ecs_cluster" {
  source                       = "../modules/ECS"
  project_name                 = module.vpc.project_name
  ecs_tasks_execution_role_arn = module.ecs_tasks_execution_role.ecs_tasks_execution_role_arn
  container_image              = var.container_image
  region                       = module.vpc.region
  private_app_subnet_az1_id    = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id    = module.vpc.private_app_subnet_az2_id
  ecs_security_group_id        = module.security_groups.ecs_security_group_id
  alb_target_group_arn         = module.application_load_balancer.alb_target_group_arn
}

# Create ASG
module "asg" {
  source           = "../modules/ASG"
  ecs_cluster_name = module.ecs_cluster.ecs_cluster_name
  ecs_service_name = module.ecs_cluster.ecs_service_name
}

# Create R53
module "R53" {
  source                             = "../modules/R53"
  domain_name                        = module.acm.domain_name
  record_name                        = var.record_name
  application_load_balancer_dns_name = module.application_load_balancer.application_load_balancer_dns_name
  application_load_balancer_zone_id  = module.application_load_balancer.application_load_balancer_zone_id
}

output "website_url" {
  value = join("", ["https://", var.record_name, ".", var.domain_name])
}