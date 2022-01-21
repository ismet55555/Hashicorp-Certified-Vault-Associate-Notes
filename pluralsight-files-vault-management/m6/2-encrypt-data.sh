# Now that we have a key, let's encrypt some plaintext
vault write transit/encrypt/ccid plaintext=$(base64 <<< "4444123412341234")

# We should capture that in JSON so it's easier to use
json_data=$(vault write transit/encrypt/ccid plaintext=$(base64 <<< "4444123412341234") -format=json)

# If we want to decrypt the data we need to submit the ciphertext with the version of the key
# And we need to refer to the correct key
ciphertext=$(echo $json_data | jq .data.ciphertext -r)

vault write transit/decrypt/ccid ciphertext=$ciphertext

# That value is still base64 encoded. Let's decode it.
plaintext=$(vault write transit/decrypt/ccid ciphertext=$ciphertext -format=json | jq .data.plaintext -r)
echo $plaintext | base64 -d