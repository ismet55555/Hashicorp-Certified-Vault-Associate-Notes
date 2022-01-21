listener "tcp" {
    address = "0.0.0.0:8200"
    cluster_address= "0.0.0.0:8201"
    tls_cert_file = "/vault/certs/vault_cert.pem"
    tls_key_file = "/vault/certs/vault_key.key"
}

storage "raft" {
    path = "/vault/data"

    node_id = "server1"

    retry_join {
        leader_api_addr = "https://server1:8200"
    }
}

ui = true

disable_mlock = true

cluster_addr = "https://server1:8201"

api_addr = "https://server1:8200"
