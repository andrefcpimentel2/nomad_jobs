job "payments" {
  datacenters = ["eu-west-2"]
  group "hashicups" {
    count = 1
    task "payments" {
      driver = "docker"
      constraint {
        attribute = "${attr.platform.aws.instance-type}"
        value     = "m4.large"
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