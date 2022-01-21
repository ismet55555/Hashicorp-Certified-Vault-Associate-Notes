# We are going to enable some auth methods for AppRole and Userpass
# Then we'll add some users to Userpass

# Make sure your Vault server container is up and running
docker container ls

# Let's set our vault env variables
$env:VAULT_ADDR="https://127.0.0.1:8200"
$env:VAULT_SKIP_VERIFY="true"

# Make sure vault isn't sealed
vault status

# And now we'll enable Userpass and add some users
vault auth enable userpass

vault write auth/userpass/users/adent password=arthur
vault write auth/userpass/users/fprefect password=ford

# Now onto AppRole, we'll use this in module 7 for Vault Agent
vault auth enable approle

vault write auth/approle/role/web-role secret_id_ttl=10m token_num_uses=0 token_ttl=60m token_max_ttl=120m secret_id_num_uses=40

# That's it! Time to create some entities and aliases
