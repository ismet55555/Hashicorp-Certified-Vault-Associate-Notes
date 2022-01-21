# Now that we have a key, let's encrypt some plaintext
$plaintext=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("4444123412341234"))
vault write transit/encrypt/ccid plaintext=$plaintext

# We should capture that in JSON so it's easier to use
$json_data = vault write transit/encrypt/ccid plaintext=$plaintext -format=json | ConvertFrom-Json

# If we want to decrypt the data we need to submit the ciphertext with the version of the key
# And we need to refer to the correct key
vault write transit/decrypt/ccid ciphertext=$($json_data.data.ciphertext)

# That value is still base64 encoded. Let's decode it.
$decrypt_json = vault write transit/decrypt/ccid ciphertext=$($json_data.data.ciphertext) -format=json | ConvertFrom-Json
$decoded = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($decrypt_json.data.plaintext))
Write-Output $decoded