
resource "aws_security_group" "vpc_ec2_instance_connect_endpoints_sgs" {
  count = length(var.vpc_private_subnets_cidr_blocks)
  #name        = format("webserver-%s", random_string.random_name.result)
  description = "VPC EC2 Instance Connect Endpoint"
  vpc_id      = aws_vpc.vpc_instance.id
  tags        = merge(var.vpc_private_acl_tags, { Name : format("%s%s", "${var.project_name}_vpc_ec2_instance_connect_endpoint_", "${var.vpc_private_subnets_availability_zones[count.index]}_${random_string.resource_name_lower_case_suffix[count.index].id}") })

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ec2_instance_connect_ip_prefix]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ec2_instance_connect_endpoint" "ec2_instance_connect_endpoints" {
  count              = length(var.vpc_private_subnets_cidr_blocks)
  depends_on         = [aws_subnet.vpc_private_subnets, aws_route_table.vpc_private_rts]
  subnet_id          = element(aws_subnet.vpc_private_subnets[*].id, count.index)
  security_group_ids = [element(aws_security_group.vpc_ec2_instance_connect_endpoints_sgs[*].id, count.index)]
  tags               = merge(var.vpc_private_acl_tags, { Name : format("%s%s", "${var.project_name}_ec2_instance_connect_endpoint_", "${var.vpc_private_subnets_availability_zones[count.index]}_${random_string.resource_name_lower_case_suffix[count.index].id}") })
}
