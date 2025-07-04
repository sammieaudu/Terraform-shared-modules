module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${local.name}-eks"
  cluster_version = var.cluster_version

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  cluster_upgrade_policy = {
    support_type = "STANDARD"
  }

  cluster_zonal_shift_config = {
    enabled = true
  }

  # Enable control plane logging
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_id     = var.eks_vpc
  control_plane_subnet_ids = var.eks_private_subnets
  subnet_ids = var.eks_private_subnets
  
  # EKS Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    eks-node-monitoring-agent = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      before_compute = true
      most_recent    = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
  
  # EKS Managed Node Group:
  eks_managed_node_groups = {
    default_node_group = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["t3.medium"]
      min_size = 2
      max_size = 5
      desired_size = 2

      # Restrict node group security group egress
      vpc_security_group_ids = [aws_security_group.node_group.id]
    }
  }

  tags = local.tags
}

# Create restricted security group for node groups
resource "aws_security_group" "node_group" {
  name_prefix = "${local.name}-node-group-"
  description = "Security group for EKS node groups"
  vpc_id      = var.eks_vpc

  egress {
    description = "Allow HTTPS to AWS services"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow NTP"
    from_port   = 123
    to_port     = 123
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-node-group-sg"
    }
  )
}

###############################
# AWS EKS Cluster Authentication
###############################
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [ module.eks ]
}

###############################
# OIDC Provider Data Source for IRSA
###############################
data "aws_iam_openid_connect_provider" "oidc_provider" {
  url = module.eks.cluster_oidc_issuer_url
  depends_on = [ module.eks ]
}

data "aws_caller_identity" "current" {}

###############################
# Kubernetes Provider
###############################
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.region
    ]
  }
}

###############################
# Helm Provider
###############################
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.region
      ]
    }
  }
}

###############################################
# EKS AUTH
###############################################
module "eks-auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AmazonEKSClusterRole"
      username = "eksadmins"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:group/Developers"
      username = "developers"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:group/DevOps"
      username = "devops"
      groups   = ["system:masters"]
    },
  ]

  depends_on = [ 
    module.eks,
    data.aws_eks_cluster_auth.cluster,
    data.aws_iam_openid_connect_provider.oidc_provider,
    data.aws_caller_identity.current
  ]
}

# ###############################
# # IRSA for External DNS
# ###############################
# # Build the assume role policy for External DNS, which requires that the service account
# # in the "kube-system" namespace with the name "external-dns" can assume this role.
# data "aws_iam_policy_document" "external_dns_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"
#     principals {
#       type        = "Federated"
#       identifiers = [data.aws_iam_openid_connect_provider.oidc_provider.arn]
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:external-dns"]
#     }
#   }
# }

# resource "aws_iam_role" "external_dns" {
#   name               = "${local.name}-external-dns"
#   assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
# }

# # Define a minimal policy giving External DNS permissions to manage Route 53 records.
# data "aws_iam_policy_document" "external_dns_policy_doc" {
#   statement {
#     actions = [
#       "route53:ChangeResourceRecordSets",
#       "route53:ListHostedZones",
#       "route53:ListResourceRecordSets"
#     ]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_policy" "external_dns_policy" {
#   name   = "${local.name}-external-dns-policy"
#   policy = data.aws_iam_policy_document.external_dns_policy_doc.json
# }

# resource "aws_iam_role_policy_attachment" "external_dns_attach" {
#   role       = aws_iam_role.external_dns.name
#   policy_arn = aws_iam_policy.external_dns_policy.arn
# }

###############################
# Helm Releases for Add-ons
###############################

# ##########################
# # External DNS
# ##########################
# resource "helm_release" "external_dns" {
#   name       = "external-dns"
#   repository = "https://kubernetes-sigs.github.io/external-dns/"
#   chart      = "external-dns"
#   namespace  = "kube-system"
#   version    = "1.16.1"

#   set {
#     name  = "provider"
#     value = "aws"
#   }
#   set {
#     name  = "aws.zoneType"
#     value = "public"
#   }
#   set {
#     name  = "txtOwnerId"
#     value = module.eks.cluster_id
#   }
#   set {
#     name  = "serviceAccount.create"
#     value = "true"
#   }
#   set {
#     name  = "serviceAccount.name"
#     value = "external-dns"
#   }
#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = aws_iam_role.external_dns.arn
#   }
#   set {
#     name  = "policy"
#     value = "sync"
#   }
#   set {
#     name  = "registry"
#     value = "txt"
#   }
#   set {
#     name  = "domainFilters[0]"
#     value = "example.com"  # Replace with your domain
#   }
#   set {
#     name  = "interval"
#     value = "1m"
#   }
#   set {
#     name  = "logLevel"
#     value = "info"
#   }
#   set {
#     name  = "sources[0]"
#     value = "service"
#   }
#   set {
#     name  = "sources[1]"
#     value = "ingress"
#   }
#   set {
#     name  = "aws.assumeRoleArn"
#     value = aws_iam_role.external_dns.arn
#   }

#   depends_on = [module.eks]
# }


##########################
# Cert Manager
##########################
# resource "helm_release" "cert_manager" {
#   name              = "cert-manager"
#   repository        = "https://charts.jetstack.io"
#   chart             = "cert-manager"
#   namespace         = "cert-manager"
#   create_namespace  = true
#   version           = "v1.17.2"  # Adjust as necessary

#   # Ensure CRDs are installed
#   set {
#     name  = "installCRDs"
#     value = "true"
#   }

#   depends_on = [module.eks, ]#module.eks-auth]
# }

#######################################
# ArgoCD
#######################################
# resource "helm_release" "argocd" {
#   name       = "argocd"
#   namespace  = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd"
#   version    = "5.46.7"

#   create_namespace = true

#   values = [
#     yamlencode({
#       server = {
#         service = {
#           type = "LoadBalancer"
#         }
#         ingress = {
#           enabled = false
#         }
#       }
#     })
#   ]

#   depends_on = [module.eks, ]#module.eks-auth]
# }