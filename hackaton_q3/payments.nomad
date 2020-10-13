job "payments" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  group "hashicups" {
    count = 1
    task "payments" {
      driver = "docker"
      constraint {
        attribute = "${attr.os.name}"
        value = "ubuntu"
      }
      config {
        image = "hashicorpdemoapp/payments:v0.0.2"
      }
      resources {
        network {
          mbits = 10
          port "http" {
            static = 9091
          }
        }
      }
      service {
        name = "payments"
        port = "http"
      }
    }
  }
}