job "frontend" {
  datacenters = ["eu-west-2","ukwest","sa-east-1","ap-northeast-1","dc1","europe-west3-dc"]
  group "hashicups" {
    count = 1
    task "nginx" {
      driver = "docker"
      constraint {
        attribute = "${attr.os.name}"
        value = "ubuntu"
      }
      config {
        image = "hashicorpdemoapp/frontend:v0.0.3"
        volumes = ["local/default.conf:/etc/nginx/conf.d/default.conf"]
        dns_servers = ["127.0.0.1"]
      }
      template {
        data = <<EOT
{{ with service "public-api" }}
{{ with index . 0 }}
server {
    listen       80;
    server_name  localhost;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host \$host;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    location /api {
        proxy_pass http://{{ .Address }}:8080;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
{{ end }}
{{ end }}
EOT
        destination = "local/default.conf"
      }
      resources {
        network {
          mbits = 10
          port "http" {
            static = 80
          }
        }
      }
      service {
        name = "frontend"
        port = "http"
        check {
            type = "http"
            port = "http"
            path = "/"
            interval = "10s"
            timeout = "4s"
        }
      }
    }
  }
}