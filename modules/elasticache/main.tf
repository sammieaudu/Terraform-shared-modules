################################################################################
# Redis Elasticache
################################################################################
resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name}-vpc"
  subnet_ids = var.database_subnet_ids[*]

  tags = local.tags
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${local.name}-redis-cluster"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t4g.small"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.this.name
  
  apply_immediately = true
  az_mode = "single-az"
  port                 = 6379
  network_type = "ipv4"
  ip_discovery = "ipv4"
  subnet_group_name = aws_elasticache_subnet_group.this.name
  security_group_ids = [module.redis_sg.security_group_id]

  maintenance_window = "sun:05:00-sun:09:00"

  tags = local.tags
  depends_on = [ module.redis_sg, aws_elasticache_parameter_group.this ]
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "redis-params"
  family = "redis7"

  parameter {
    name  = "latency-tracking"
    value = "yes"
  }

  tags = local.tags

}

################################################################################
# Redis Users / Group
################################################################################
resource "aws_elasticache_user" "this" {
    user_id = "redisUser"
    user_name = "default"
    engine = "redis"
    access_string = "on ~* +@all"
    no_password_required = true

    authentication_mode {
      type = "no-password-required"
    }
    tags = local.tags

    lifecycle {
      ignore_changes = [ user_id ]
    }
}

resource "aws_elasticache_user_group" "this" {
  engine = "redis"
  user_group_id = "redisUserGoup"
  user_ids = [ aws_elasticache_user.this.user_id]

  lifecycle {
    ignore_changes = [ user_ids ]
  }

  tags = local.tags
}

################################################################################
# Security Group
################################################################################
module "redis_sg" {
    source = "../sg"
    env = var.env
    sg_name = "${local.name}-redis-sg"
    sg_description = "Complete Redis security group"
    vpc_id = var.vpc_id
    ingress_with_cidr_blocks = [
    {
      from_port   = 6379
      to_port     = 6379
      protocol    = "tcp"
      description = "ElastiCache (Redis) access from within VPC"
      cidr_blocks = var.vpc_cidr
    },
  ]
}