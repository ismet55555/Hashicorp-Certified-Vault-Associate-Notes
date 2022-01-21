# Allow access to all apikeys data
path "apikeys/data/*" {
    capabilities = ["read", "list"]
}

# Allow access to metadata for kv2
path "apikeys/metadata/*" {
    capabilities = ["list"]
}