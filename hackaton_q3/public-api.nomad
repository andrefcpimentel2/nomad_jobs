job "public-api" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  group "hashicups" {
    count = 1
    task "public-api" {
      driver = "docker"
      constraint {
        attribute = "${attr.os.name}"
        value = "ubuntu"
      }
      env {
          BIND_ADDRESS = ":8080"
          PRODUCT_API_URI = "http://product-api.service.consul:9090"
      }
      config {
        image = "hashicorpdemoapp/public-api:v0.0.1"
        dns_servers = ["127.0.0.1"]
      }
      resources {
        network {
          mbits = 10
          port "public_api" {
            static = 8080
          }
        }
      }
      service {
        name = "public-api"
        port = "public_api"
        check {
            type = "http"
            port = "public_api"
            path  = "/"
            interval = "10s"
            timeout = "4s"
        }
      }
    }
  }
}