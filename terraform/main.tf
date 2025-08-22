terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  region = var.aws_region
}

# 🔹 Create EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnets

  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size     = 3
      min_size     = 1
      instance_types = ["t3.medium"]
    }
  }
}

# 🔹 Configure Kubernetes provider using cluster auth
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = module.eks.cluster_token
}

# 🔹 Deploy MongoDB
resource "kubernetes_deployment" "mongo" {
  metadata {
    name      = "mongo"
    namespace = "default"
    labels = {
      app = "mongo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mongo"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongo"
        }
      }

      spec {
        container {
          name  = "mongo"
          image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/mongo:latest"

          port {
            container_port = 27017
          }
        }
      }
    }
  }
}

# 🔹 Mongo Service
resource "kubernetes_service" "mongo" {
  metadata {
    name      = "mongo"
    namespace = "default"
  }

  spec {
    selector = {
      app = "mongo"
    }

    port {
      port        = 27017
      target_port = 27017
    }

    type = "ClusterIP"
  }
}

# 🔹 Deploy Rocket.Chat
resource "kubernetes_deployment" "rocketchat" {
  metadata {
    name      = "rocketchat"
    namespace = "default"
    labels = {
      app = "rocketchat"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "rocketchat"
      }
    }

    template {
      metadata {
        labels = {
          app = "rocketchat"
        }
      }

      spec {
        container {
          name  = "rocketchat"
          image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/rocketchat:latest"

          env {
            name  = "MONGO_URL"
            value = "mongodb://mongo:27017/rocketchat"
          }

          env {
            name  = "ROOT_URL"
            value = "http://localhost:4000"
          }

          port {
            container_port = 4000
          }
        }
      }
    }
  }
}

# 🔹 Rocket.Chat Service (LoadBalancer)
resource "kubernetes_service" "rocketchat" {
  metadata {
    name      = "rocketchat"
    namespace = "default"
  }

  spec {
    selector = {
      app = "rocketchat"
    }

    port {
      port        = 4000
      target_port = 4000
    }

    type = "LoadBalancer"
  }
}
