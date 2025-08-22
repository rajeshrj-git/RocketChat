output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rocketchat_service_url" {
  description = "Public LoadBalancer URL to access Rocket.Chat"
  value       = kubernetes_service.rocketchat.status[0].load_balancer[0].ingress[0].hostname
}
