variable "mysql_version" {
  default = "5.6"
}
//Create k8s Service for mysql
resource "kubernetes_service" "mysql" {
  metadata {
    name      = "wordpress-mysql"
    namespace = "app"
    labels = {
      app  = "wordpress"
      tier = kubernetes_replication_controller.mysql.spec[0].selector.tier
    }
  }
  spec {
    port {
      port        = 3306
      target_port = 3306
    }
    selector = {
      app = "wordpress"
    }
    
  }
}

//Create k8s pvc for mysql
resource "kubernetes_persistent_volume_claim" "mysql" {
  metadata {
    name      = "mysql-pv-claim"
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

//Secretes for mysql
resource "kubernetes_secret" "mysql" {
  metadata {
    name      = "mysql-pass"
    namespace = "app"
  }

  data = {
    password = var.mysql_password
  }
}

//Create rs for mysql
resource "kubernetes_replication_controller" "mysql" {
  metadata {
    name      = "wordpress-mysql"
    namespace = "app"
    labels = {
      app = "wordpress"
    }
  }
  spec {
    selector = {
      app  = "wordpress"
      tier = "backend"
    }
    template {
      container {
        image = "mysql:${var.mysql_version}"
        name  = "mysql"

        env {
          name = "MYSQL_ROOT_PASSWORD"
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
          container_port = 3306
          name           = "mysql"
        }


        volume_mount {
          name       = "mysql-persistent-storage"
          mount_path = "/var/lib/mysql"
        }
      }

      volume {
        name = "mysql-persistent-storage"
        persistent_volume_claim {
          claim_name = kubernetes_persistent_volume_claim.mysql.metadata[0].name
        }
      }
    }
  }
}
