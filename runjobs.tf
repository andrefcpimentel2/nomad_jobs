# Configure the Nomad provider
provider "nomad" {
  address = data.terraform_remote_state.demostack.outputs.Primary_Nomad
}

// Workspace Data
data "terraform_remote_state" "demostack" {
  backend = "remote"

  config = {
    hostname     = "app.terraform.io"
    organization = var.TFE_ORGANIZATION
    workspaces = {
      name = var.DEMOSTACK_WORKSPACE
    }
  } //config
}


# Register a job
# resource "nomad_job" "nginx-pki" {
#   jobspec = "${file("./nginx-pki.nomad")}"
# }

# resource "nomad_job" "hashibo" {
#   jobspec = "${file("./hashibo.nomad")}"
# }

# resource "nomad_job" "ldap-server" {
#   jobspec = "${file("./ldap-server.nomad")}"
# }
# resource "nomad_job" "phpldapadmin" {
#   jobspec = "${file("./phpldapadmin.nomad")}"
# }

resource "nomad_job" "payments" {
  jobspec = "${file("hackaton_q3/payments.nomad")}"
}

resource "nomad_job" "frontend" {
  jobspec = "${file("hackaton_q3/frontend.nomad")}"
}

resource "nomad_job" "product-api" {
  jobspec = "${file("hackaton_q3/product-api.nomad")}"
}

resource "nomad_job" "product-db" {
  jobspec = "${file("hackaton_q3/product-db.nomad")}"
}

resource "nomad_job" "public-api" {
  jobspec = "${file("hackaton_q3/public-api.nomad")}"
}