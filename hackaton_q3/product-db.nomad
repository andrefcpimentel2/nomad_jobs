job "product-db" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  group "hashicups" {
    count = 1
    task "product-db" {
      driver = "docker"
      constraint {
        attribute = "${attr.os.name}"
        value = "ubuntu"
      }
      config {
        image = "hashicorpdemoapp/product-api-db:v0.0.11"
      }
      env {
          POSTGRES_USER="postgres",
          POSTGRES_PASSWORD="password"
          POSTGRES_DB="products"
      }
      logs {
        max_files     = 5
        max_file_size = 15
      }
      resources {
        network {
          mbits = 10
          port "db" {
            static = 5432
          }
        }
      }
      service {
        name = "product-db"
        port = "db"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
  }
}