provider "kubernetes" { 
}

// Terraform script to create namespace named app for Wordpress Application
resource "kubernetes_namespace" "wordpress-ns" {
  metadata {
    annotations = {
      name = "wordpress-app"
    }
    labels = {
      mylabel = "label-value"
    }

    name = "app"
  }
}
