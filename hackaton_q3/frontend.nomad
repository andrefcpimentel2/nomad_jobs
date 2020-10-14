job "frontend" {
    datacenters = ["eu-west-2"]
    type = "service"
    group "hashicups" {
        count = 1
        task "frontend" {
            template {
                data = <<EOF
# /etc/nginx/conf.d/default.conf
server {
    listen       80;
    server_name  localhost;
    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    # Proxy pass the api location to save CORS
    # Use location exposed by Consul connect
    location /api {
        proxy_pass http://workers-0.eu-andrestack.andrestack.aws.hashidemos.io:8080;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
                EOF
                destination = "local/default.conf"
            }
            driver = "docker"
            config {
                image = "hashicorpdemoapp/frontend:v0.0.3"
                volumes = ["local/default.conf:/etc/nginx/conf.d/default.conf"]
 
            }
            resources {
                network {
                    mbits = 10
                    port  "http"{
                    static = 80
                    }
                }
            }
            service {
                name = "frontend"
                tags = ["hashicups"]
                address_mode = "host"
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