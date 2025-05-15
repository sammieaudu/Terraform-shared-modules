################################################################################
# Supporting Resources
################################################################################
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = var.sg_name
  description = var.sg_description
  vpc_id      = var.vpc_id 

  # ingress
  ingress_with_cidr_blocks = var.ingress_with_cidr_blocks

  tags = local.tags
}