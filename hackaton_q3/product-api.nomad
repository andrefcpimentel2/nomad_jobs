# This Works - docker run -d -p 9090:9090 -v /app/conf.json:/conf.json hashicorpdemoapp/product-api:v0.0.11
# Test - curl http://localhost:9090/coffees | jq
job "product-api" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  group "hashicups" {
    count = 1
    task "product-api" {
      driver = "docker"
      constraint {
        attribute = "${attr.platform.aws.instance-type}"
        value     = "m4.large"
      }
      config {
        image = "hashicorpdemoapp/product-api:v0.0.11"
      }
      env {
          CONFIG_FILE = "/secrets/conf.json"
      }
      template {
        data = <<EOT
{{ with service "product-db" }}
{{ with index . 0 }}
{
  "db_connection": "host=workers-0.eu-andrestack.andrestack.aws.hashidemos.io port=5432 user=postgres password=password dbname=products sslmode=disable",
  "bind_address": ":9090",
  "metrics_address": ":9103"
}
{{ end }}
{{ end }}
EOT
        destination = "/secrets/conf.json"
      }
      resources {
        network {
          mbits = 10
          port "product_api" {
            static = 9090
          }
        }
      }
      service {
        name = "product-api"
        port = "product_api"
        check {
            type = "http"
            port = "product_api"
            path = "/health"
            interval = "10s"
            timeout = "4s"
        }
      }
    }
  }
}