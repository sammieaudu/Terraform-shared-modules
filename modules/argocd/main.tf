#######################################
# modules/argocd/main.tf
#######################################
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.7"

  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
        ingress = {
          enabled = false
        }
      }
    })
  ]
}

#######################################
# modules/argocd/variables.tf
#######################################
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

#######################################
# modules/argocd/outputs.tf
#######################################
output "argocd_server_service" {
  description = "ArgoCD LoadBalancer service for UI"
  value = {
    name      = helm_release.argocd.name
    namespace = helm_release.argocd.namespace
  }
}
