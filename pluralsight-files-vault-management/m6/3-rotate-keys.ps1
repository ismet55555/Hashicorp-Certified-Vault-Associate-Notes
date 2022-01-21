# What if we want to rotate the encryption keys?
vault write -force transit/keys/ccid/rotate

# Let's get info about the key now
vault read transit/keys/ccid

# We can still decrypt data using the old key
vault write transit/decrypt/ccid ciphertext=$($json_data.data.ciphertext)

# If we try and encrypt a new piece of data, it will use the new key
$plaintext=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("4444123412341234"))
vault write transit/encrypt/ccid plaintext=$plaintext

# Let's rotate the key a few more times
vault write -force transit/keys/ccid/rotate

# And we'll set the minimum version availble to 2
vault write transit/keys/ccid/config min_decryption_version=2

# If we try and decrypt our old ciphertext now, we'll get an error
vault write transit/decrypt/ccid ciphertext=$($json_data.data.ciphertext)

# The key is still there
vault read transit/keys/ccid 

# If we want to purge an older key, we need to set the min encryption version
# and then we can trim the keys
vault write transit/keys/ccid/config min_encryption_version=2
vault write transit/keys/ccid/trim min_available_version=2

# Now the key version 1 is gone and you can't get it back
vault read transit/keys/ccid 
