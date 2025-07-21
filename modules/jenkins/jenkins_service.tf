resource "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"
    labels = {
      app = "jenkins"
    }
  }

  spec {
    selector = {
      app = "jenkins"
    }

    port {
      name       = "http"
      port       = 8080
      target_port = 8080
    }

    port {
      name       = "jnlp"
      port       = 50000
      target_port = 50000
    }

    type = "LoadBalancer"
  }
}
