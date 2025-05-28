
data "http" "ec2_instance_connect_ip_ranges_json_content" {
  url = var.ec2_instance_connect_ip_ranges_json_url

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "null_resource" "example" {
  provisioner "local-exec" {
    command = contains([200], data.http.ec2_instance_connect_ip_ranges_json_content.status_code)
  }
}

locals {
  ec2_instance_connect_ip_prefix = [for ec2_instance_connect_entry in jsondecode(data.http.ec2_instance_connect_ip_ranges_json_content.response_body)["prefixes"] : ec2_instance_connect_entry
  if ec2_instance_connect_entry["service"] == "EC2_INSTANCE_CONNECT" && ec2_instance_connect_entry["region"] == var.aws_region][0]["ip_prefix"]
}

module "vpc_ipv4_network_instance" {
  source                   = "../../../tf_modules/aws/vpc_ipv4_network/"
  project_name             = local.common_tags.PROJECT_NAME
  vpc_ipv4_cidr_block      = local.vpc_ipv4_cidr_block
  vpc_tenancy              = local.vpc_tenancy
  vpc_enable_dns_support   = var.vpc_enable_dns_support
  vpc_enable_dns_hostnames = var.vpc_enable_dns_hostnames
  vpc_tags                 = merge(local.common_tags, { Name : "${local.common_tags.PROJECT_NAME}_vpc" }, { "TF_LAYER_NAME" : var.tf_layer_name })
  vpc_igw_instance_tags    = merge(local.common_tags, { Name : "${local.common_tags.PROJECT_NAME}_vpc_igw" }, { "TF_LAYER_NAME" : var.tf_layer_name })

  vpc_public_subnets_cidr_blocks             = local.public_network_ipv4_cidr_blocks
  vpc_public_subnets_map_public_ip_on_launch = true
  vpc_public_subnets_availability_zones      = local.supported_available_zones
  vpc_public_subnets_tags                    = merge(local.common_tags, { "TF_LAYER_NAME" : var.tf_layer_name })

  vpc_private_subnets_cidr_blocks        = local.private_network_ipv4_cidr_blocks
  vpc_private_subnets_availability_zones = local.supported_available_zones
  vpc_private_subnets_tags               = merge(local.common_tags, { "TF_LAYER_NAME" : var.tf_layer_name })

  ipv4_cidr_block_to_all_ip_addresses = local.ipv4_cidr_block_containing_all_ip_addresses
  vpc_public_route_table_tags         = merge(local.common_tags, { Name : "${local.common_tags.PROJECT_NAME}_vpc_public_subnet_rt" })

  vpc_private_route_table_tags = merge(local.common_tags, { "TF_LAYER_NAME" : var.tf_layer_name })
  vpc_nat_gateway_tags         = merge(local.common_tags, { "TF_LAYER_NAME" : var.tf_layer_name })
  vpc_nat_gws_eips_tags        = merge(local.common_tags, { "TF_LAYER_NAME" : var.tf_layer_name })

  vpc_public_acl_tags  = merge(local.common_tags, { "TF_LAYER_NAME" : var.tf_layer_name })
  vpc_private_acl_tags = merge(local.common_tags, { "TF_LAYER_NAME" : var.tf_layer_name })

  random_strings_count           = length(local.supported_available_zones) * 5
  ec2_instance_connect_ip_prefix = local.ec2_instance_connect_ip_prefix
}
