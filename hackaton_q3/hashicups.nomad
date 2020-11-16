job "hashicups" {
  # Defining which data center in which to deploy the service
  datacenters = ["eu-west-2"]

  # Define Nomad Scheduler to be used (Service/Batch/System)
  type     = "service"

  # Each component is defined within it's own Group
  group "postgres" {
    count = 1

    # Host volume on which to store Postgres Data.  Nomad will confirm the client offers the same volume for placement.
    volume "pgdata" {
      type      = "host"
      read_only = false
      source    = "pgdata"
    }

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    #Actual Postgres task using the Docker Driver
    task "postgres" {
      driver = "docker"
      constraint {
                attribute = "${attr.platform.aws.instance-type}"
                value     = "m4.large"
            }
      volume_mount {
        volume      = "pgdata"
        destination = "/var/lib/postgresql/data"
        read_only   = false
        }

     # Postgres Docker image location and configuration
     config {
        image = "hashicorpdemoapp/product-api-db:v0.0.11"
        network_mode = "host"
        port_map {
          db = 5432
        }
      }

      # Task relevant environment variables necessary
      env {
          POSTGRES_USER="root"
          POSTGRES_PASSWORD="password"
          POSTGRES_DB="products"
      }

      logs {
        max_files     = 5
        max_file_size = 15
      }

      # Host machine resources required
      resources {
        cpu = 100 #1000
        memory = 300 #1024
        network {
          port  "db"  {
            static = 5432
          }
        }
      }

      # Service definition to be sent to Consul
      service {
        name = "postgres"
        port = "db"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    } # end postgres task
  } # end postgres group

  # Products API component that interfaces with the Postgres database
  group "products-api" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "products-api" {
      driver = "docker"
      constraint {
                attribute = "${attr.platform.aws.instance-type}"
                value     = "m4.large"
            }
      # Creation of the template file defining how the API will access the database
      template {
        destination   = "/secrets/db-creds"
        data = <<EOF
{
  "db_connection": "host=workers-0.hackatonq3.andrestack.aws.hashidemos.io port=5432 user=root password=password dbname=products sslmode=disable",
  "bind_address": ":9090",
  "metrics_address": ":9103"
}
EOF
      }

      # Task relevant environment variables necessary
      env = {
        "CONFIG_FILE" = "/secrets/db-creds"
      }

      # Product-api Docker image location and configuration
      config {
        image = "hashicorpdemoapp/product-api:v0.0.11"
        port_map {
          http_port = 9090
        }
      }

      # Host machine resources required
      resources {
        #cpu    = 500
        #memory = 1024
        network {
          #mbits = 10
          port  "http_port"  {
            static = 9090
          }
        }
      }

      # Service definition to be sent to Consul with corresponding health check
      service {
        name = "products-api-server"
        port = "http_port"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.products.entrypoints=products",
          "traefik.http.routers.products.rule=Path(`/`)",
        ]
        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    } # end products-api task
  } # end products-api group

  # Public API component
  group "public-api" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "public-api" {
      driver = "docker"
      constraint {
                attribute = "${attr.platform.aws.instance-type}"
                value     = "m4.large"
            }
      # Task relevant environment variables necessary
      env = {
        BIND_ADDRESS = ":8080"
        PRODUCT_API_URI = "http://workers-0.hackatonq3.andrestack.aws.hashidemos.io:9090"
      }

      # Public-api Docker image location and configuration
      config {
        image = "hashicorpdemoapp/public-api:v0.0.2"

        port_map {
          pub_api = 8080
        }
      }

      # Host machine resources required
      resources {
        #cpu    = 500
        #memory = 1024

        network {
          port "pub_api" {
            static = 8080
          }
        }
      }

      # Service definition to be sent to Consul with corresponding health check
      service {
        name = "public-api-server"
        port = "pub_api"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.public.entrypoints=public",
          "traefik.http.routers.public.rule=Path(`/`)",
        ]
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }

  # Frontend component providing user access to the application

  group "frontend" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay    = "15s"
      mode     = "delay"
    }

    task "server" {
      driver = "docker"
      constraint {
                attribute = "${attr.platform.aws.instance-type}"
                value     = "m4.large"
            }
      # Task relevant environment variables necessary
      env {
        PORT    = "${NOMAD_PORT_http}"
        NODE_IP = "${NOMAD_IP_http}"
      }

      # Frontend Docker image location and configuration
      config {
        image = "hashicorpdemoapp/frontend:v0.0.3"
        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      # Creation of the NGINX configuration file
      template {
        data = <<EOF
server {
    listen       80;
    server_name  localhost;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host $host;
    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    location /api {
        proxy_pass http://workers-0.hackatonq3.andrestack.aws.hashidemos.io:8080;
    }
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
        destination   = "local/default.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      # Host machine resources required
      resources {
        network {
          mbits = 10
          port  "http"{
            static = 80
          }
        }
      }

      # Service definition to be sent to Consul with corresponding health check
      service {
        name = "frontend"
        port = "http"

        tags = [
          # "traefik.enable=true",
          # "traefik.http.routers.frontend.rule=Path(`/frontend`)",
          "traefik.enable=true",
          "traefik.http.routers.frontend.entrypoints=frontend",
          "traefik.http.routers.frontend.rule=Path(`/`)",
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}
