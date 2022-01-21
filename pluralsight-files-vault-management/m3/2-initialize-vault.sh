# Check on the status of the Vault server
vault status

# Now we'll initialize Vault
vault operator init -key-shares=3 -key-threshold=2

# Copy the output to a text file, you will need this info!

# We'll need to run unseal twice
vault operator unseal