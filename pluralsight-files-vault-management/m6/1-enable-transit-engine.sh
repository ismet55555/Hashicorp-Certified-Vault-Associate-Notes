# We're going to enable the transit engine and then use it to encrypt some data

# Make sure your Vault server container is up and running
docker container ls

# Let's set our vault env variables
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true

# Make sure vault isn't sealed
vault status
vault login

# Now let's enable the transit engine at the default path
vault secrets enable transit

# Is there anything to configure here? Let's run path-help to check
vault path-help transit/

# You can configure the caching strategy, which defaults to unlimited

# Let's do some encryption work!

# First we'll create an encryption key to use
vault write -force transit/keys/ccid

# Let's check out some info about the key
vault list transit/keys
vault read transit/keys/ccid

# If you want to know more about these fields, use our friend path-help
vault path-help transit/keys/ccid/config