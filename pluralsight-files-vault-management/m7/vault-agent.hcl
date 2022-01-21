vault {
    address = "https://127.0.0.1:8200"
    tls_skip_verify = "true"
}

auto_auth {
    method "approle" {
        mount_path = "auth/approle"
        config = {
          role_id_file_path = "role_id.txt"
          secret_id_file_path = "secret_id.txt"
          remove_secret_id_file_after_reading = false
        }
    }

    sink "file" {
        config = {
            path = "token.txt"
        }
    }

}

cache {
    use_auto_auth_token = true
}

listener "tcp" {
  address = "127.0.0.1:8100"
  tls_disable = true
}

template {
  source = "template.ctmpl"
  destination = "render.txt"
}