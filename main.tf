provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "rocketchat" {
  metadata {
    name = "rocketchat"
  }
}

resource "kubernetes_deployment" "mongo" {
  metadata {
    name      = "mongo"
    namespace = kubernetes_namespace.rocketchat.metadata[0].name
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
          image = "rajeshchoco/mongo:6.0"
          args  = ["--oplogSize=128", "--replSet=rs0", "--storageEngine=wiredTiger", "--bind_ip_all"]

          port {
            container_port = 27017
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "rocketchat" {
  metadata {
    name      = "rocketchat"
    namespace = kubernetes_namespace.rocketchat.metadata[0].name
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
          image = "rajeshchoco/rocketchat:7.9.3"

          env {
            name  = "MONGO_URL"
            value = "mongodb://mongo:27017/rocketchat?replicaSet=rs0"
          }

          ports {
            container_port = 3000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "rocketchat" {
  metadata {
    name      = "rocketchat-service"
    namespace = kubernetes_namespace.rocketchat.metadata[0].name
  }
  spec {
    selector = {
      app = "rocketchat"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}
