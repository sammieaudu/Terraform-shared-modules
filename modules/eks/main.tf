module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${local.name}-eks-cluster"
  cluster_version = var.cluster_version

  # Optional
  cluster_endpoint_public_access = false

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id     = var.eks_vpc
  subnet_ids = var.eks_subnet
  
  # EKS Addons
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
  }
  
  # Fargate Profiles determine which pods run on Fargate.
  fargate_profiles = {
    coredns-fargate-profile = {
      name = "coredns"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        },
        {
          namespace = "default"
        }
      ]
      subnets = flatten([var.eks_subnet])
    }
  }

  tags = local.tags
}

################################################
# EKS AUTH
################################################
# module "eks-auth" {
#   source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
#   version = "~> 20.0"

#   manage_aws_auth_configmap = true

#   aws_auth_roles = [
#     {
#       rolearn  = "arn:aws:iam::${var.account}:role/role1"
#       username = "role1"
#       groups   = ["system:masters"]
#     },
#   ]

#   aws_auth_users = [
#     {
#       userarn  = "arn:aws:iam::${var.account}:user/user1"
#       username = "user1"
#       groups   = ["system:masters"]
#     },
#     {
#       userarn  = "arn:aws:iam::${var.account}:user/user2"
#       username = "user2"
#       groups   = ["system:masters"]
#     },
#   ]

#   # aws_auth_accounts = [
#   #   "777777777777",
#   #   "888888888888",
#   # ]
# }

  ###############################
  # AWS EKS Cluster Authentication
  ###############################
  data "aws_eks_cluster_auth" "cluster" {
    name = module.eks.cluster_name
  }
  
  ###############################
  # Kubernetes Provider
  ###############################
  provider "kubernetes" {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
  
  ###############################
  # Helm Provider
  ###############################
  provider "helm" {
    kubernetes {
      host                   = module.eks.cluster_endpoint
      cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }
  }
  
  ###############################
  # OIDC Provider Data Source for IRSA
  ###############################
  data "aws_iam_openid_connect_provider" "oidc_provider" {
    url = module.eks.cluster_oidc_issuer_url
  }
  
  ###############################
  # IRSA for External DNS
  ###############################
  # Build the assume role policy for External DNS, which requires that the service account
  # in the "kube-system" namespace with the name "external-dns" can assume this role.
  data "aws_iam_policy_document" "external_dns_assume_role_policy" {
    statement {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      effect  = "Allow"
      principals {
        type        = "Federated"
        identifiers = [data.aws_iam_openid_connect_provider.oidc_provider.arn]
      }
      condition {
        test     = "StringEquals"
        variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
        values   = ["system:serviceaccount:kube-system:external-dns"]
      }
    }
  }
  
  resource "aws_iam_role" "external_dns" {
    name               = "${local.name}-external-dns"
    assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
  }
  
  # Define a minimal policy giving External DNS permissions to manage Route 53 records.
  data "aws_iam_policy_document" "external_dns_policy_doc" {
    statement {
      actions = [
        "route53:ChangeResourceRecordSets",
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ]
      resources = ["*"]
    }
  }
  
  resource "aws_iam_policy" "external_dns_policy" {
    name   = "${local.name}-external-dns-policy"
    policy = data.aws_iam_policy_document.external_dns_policy_doc.json
  }
  
  resource "aws_iam_role_policy_attachment" "external_dns_attach" {
    role       = aws_iam_role.external_dns.name
    policy_arn = aws_iam_policy.external_dns_policy.arn
  }
  
  ###############################
  # Helm Releases for Add-ons
  ###############################
  
  ##########################
  # External DNS
  ##########################
  resource "helm_release" "external_dns" {
    name       = "external-dns"
    repository = "https://kubernetes-sigs.github.io/external-dns/"
    chart      = "external-dns"
    namespace  = "kube-system"
    version    = "1.14.0"  # Adjust as required
  
    # Configure External DNS values
    set {
      name  = "provider"
      value = "aws"
    }
    set {
      name  = "aws.zoneType"
      value = "public"
    }
    set {
      name  = "txtOwnerId"
      value = module.eks.cluster_id
    }
    # Configure the service account to use the IRSA role
    set {
      name  = "serviceAccount.create"
      value = "true"
    }
    set {
      name  = "serviceAccount.name"
      value = "external-dns"
    }
    set {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_dns.arn
    }
  
    depends_on = [module.eks]
  }
  
  ##########################
  # Kube State Metrics
  ##########################
  resource "helm_release" "kube_state_metrics" {
    name       = "kube-state-metrics"
    repository = "https://kubernetes.github.io/kube-state-metrics"
    chart      = "kube-state-metrics"
    namespace  = "kube-system"
    version    = "3.4.0"  # Adjust as required
  
    depends_on = [module.eks]
  }
  
  ##########################
  # Cert Manager
  ##########################
  resource "helm_release" "cert_manager" {
    name              = "cert-manager"
    repository        = "https://charts.jetstack.io"
    chart             = "cert-manager"
    namespace         = "cert-manager"
    create_namespace  = true
    version           = "v1.9.1"  # Adjust as necessary
  
    # Ensure CRDs are installed
    set {
      name  = "installCRDs"
      value = "true"
    }
  
    depends_on = [module.eks]
  }
  
  ##########################
  # Metrics Server
  ##########################
  resource "helm_release" "metrics_server" {
    name       = "metrics-server"
    repository = "https://kubernetes-sigs.github.io/metrics-server/"
    chart      = "metrics-server"
    namespace  = "kube-system"
    version    = "3.8.2"  # Adjust as appropriate
  
    depends_on = [module.eks]
  }
 