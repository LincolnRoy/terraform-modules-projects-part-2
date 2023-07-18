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
  source = "../modules/SG"
  vpc_id = module.vpc.vpc_id
  project_name = module.vpc.project_name
}