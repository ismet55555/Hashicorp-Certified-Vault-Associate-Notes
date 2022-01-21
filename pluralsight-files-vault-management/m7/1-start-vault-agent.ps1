# Make sure you are in the m7 directory or this won't work very well

# Make sure your Vault server container is up and running
docker container ls

# Let's set our vault env variables
$env:VAULT_ADDR="https://127.0.0.1:8200"
$env:VAULT_SKIP_VERIFY="true"

# Make sure vault isn't sealed
vault status
vault login

# We need to get the role-id and secret-id for the vault agent
$role_id=$(vault read auth/approle/role/web-role/role-id -format=json) | ConvertFrom-Json

$secret_id=$(vault write -f auth/approle/role/web-role/secret-id -format=json) | ConvertFrom-Json

# Now we'll write both values out to files for use by the agent
$role_id.data.role_id > role_id.txt
$secret_id.data.secret_id > secret_id.txt

# Next we'll put a secret into the apikeys secrets engine
vault kv put apikeys/key1 key=456yujnbgty678ikjhgty67u

# And now we can start up the vault agent
vault agent -config=vault-agent.hcl