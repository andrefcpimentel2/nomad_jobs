job "public-api" {
  datacenters = ["eu-west-2"]
  group "hashicups" {
    count = 1
    task "public-api" {
      driver = "docker"
      constraint {
        attribute = "${attr.platform.aws.instance-type}"
        value     = "m4.large"
      }
      env {
          BIND_ADDRESS = ":8080"
          PRODUCT_API_URI = "http://workers-0.eu-andrestack.andrestack.aws.hashidemos.io/:9090"
      }
      config {
        image = "hashicorpdemoapp/public-api:v0.0.1"
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