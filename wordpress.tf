//Create Wordpress lb
resource "kubernetes_service" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = "app"
    labels = {
      app = "wordpress"
    }
  }
  spec {
    port {
      port        = 80
      target_port = 80

    }
    selector = {
      app = "wordpress"
      tier = kubernetes_replication_controller.wordpress.spec[0].selector.tier
    }
    type = "NodePort"
  }
}

output "node_port" {
  value = "${kubernetes_service.wordpress.spec.0.port.0.node_port} Run <kubectl get node -o wide> command to get the IP address"


}

//Create pvc for Wordpress
resource "kubernetes_persistent_volume_claim" "wordpress" {
  metadata {
    name      = "wp-pv-claim"
    namespace = "app"
    labels = {
      app = "wordpress"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }

  }
}

// Create rs for WordPress
resource "kubernetes_replication_controller" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = "app"
    labels = {
      app = "wordpress"
    }
  }
  spec {
    selector = {
      app  = "wordpress"
      tier = "frontend"
    }
    template {
      container {
        image = "wordpress:${var.wordpress_version}-apache"
        name  = "wordpress"

        env {
          name  = "WORDPRESS_DB_HOST"
          value = "wordpress-mysql"
        }
        env {
          name = "WORDPRESS_DB_PASSWORD"
          value_from {
            secret_key_ref {
              name = kubernetes_secret.mysql.metadata[0].name
              key  = "password"
            }
          }
        }
        env {
          name  = "GET_HOSTS_FROM"
          value = "dns"
        }

        port {
          container_port = 80
          name           = "wordpress"
        }
        // Define mount location
        volume_mount {
          name       = "wordpress-persistent-storage"
          mount_path = "/var/www/html"
        }
      }
      // Claim the pv
      volume {
        name = "wordpress-persistent-storage"
        persistent_volume_claim {
          claim_name = kubernetes_persistent_volume_claim.wordpress.metadata[0].name
        }
      }
    }
  }
}
