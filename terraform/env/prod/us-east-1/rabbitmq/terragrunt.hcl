locals {
    region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

dependency "vpc" {
    config_path = "../vpc"
    mock_outputs = {
        vpc_output = "mock-vpc-output"
        private_subnet_id = "4739385"
        vpc_cidr = "0.0.0.0/0"
        vpc_id = "382757"
    }
}
dependency "shared_vpc" {
    config_path = "../../../shared/${local.region_vars.inputs.region}/vpc"
    mock_outputs = {
        shared_vpc_output = "mock-shared_vpc-output"
        vpc_cidr = "0.0.0.0/0"
        private_subnet_id = "24827527"
    }
}

terraform {
    source = "../../../../modules/ec2"
}

include {
  path = find_in_parent_folders("region.hcl")
}

inputs = {
    security_group_vpc_id = dependency.vpc.outputs.vpc_id
    ec2_subnet_id = dependency.vpc.outputs.private_subnet_id
    instance_type = "t2.micro"
    ec2_name_tag = "rabbitmq"
    ingress_rules = [
        {
            from_port = 22
            to_port = 22
            protocol = "tcp"
            cidr = dependency.shared_vpc.outputs.vpc_cidr
        },
        {
            from_port = 5672
            to_port = 5672
            protocol = "tcp"
            cidr = dependency.vpc.outputs.vpc_cidr
        }
    ]
    ami = "ami-084568db4383264d4"
    env = local.region_vars.inputs.env
    key_name = local.region_vars.inputs.key_name
}