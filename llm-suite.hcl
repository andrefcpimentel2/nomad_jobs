job "llm-stack" {
  datacenters = ["eu-west-2a","eu-west-2b","eu-west-2c","eu-west-2"]
  type        = "service"

  # Constraint: Ensure the job lands on a node with GPU support (optional but recommended)
  # constraint {
  #   attribute = "${driver.docker.gpu.enabled}"
  #   value     = "true"
  # }

  group "llm" {
    count = 1

    # Networking: Bridge mode allows tasks to share localhost
    network {
      mode = "bridge"
      
      # Expose OpenWebUI port
      port "http" {
        to = 8080
      }
    }

    # Volume for Ollama Models (Client must define host_volume "ollama_data")
    volume "ollama_data" {
      type      = "host"
      source    = "ollama-data-host"
      read_only = false
    }

    # Volume for OpenWebUI History (Client must define host_volume "webui_data")
    volume "webui_data" {
      type      = "host"
      source    = "webui-data-host"
      read_only = false
    }

    # TASK: OLLAMA (The Backend)
    task "ollama" {
      driver = "docker"

      config {
        image = "ollama/ollama:latest"
        
        # GPU Configuration
        # Uncomment the device block below if running on a GPU instance
        # device "gpu" {
        #   count = 1
        # }
      }

      # Mount volume to persist downloaded models
      volume_mount {
        volume      = "ollama_data"
        destination = "/root/.ollama"
        read_only   = false
      }

      resources {
        cpu    = 2000 # 2 Cores
        memory = 4096 # 4GB System RAM (Models load into VRAM mostly)
      }

      service {
        name = "ollama"
        port = "11434"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    # TASK: OPEN-WEBUI (The Frontend)
    task "open-webui" {
      driver = "docker"

      config {
        image = "ghcr.io/open-webui/open-webui:main"
      }

      env {
        # Since we use bridge network, WebUI finds Ollama on localhost
        OLLAMA_BASE_URL = "http://localhost:11434"
      }

      # Mount volume to persist user chats/settings
      volume_mount {
        volume      = "webui_data"
        destination = "/app/backend/data"
        read_only   = false
      }

      resources {
        cpu    = 1000
        memory = 1024
      }

      service {
        name = "open-webui"
        port = "http"
        
        tags = [
          "global",
          "urlprefix-/open-webui"
          ]

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}