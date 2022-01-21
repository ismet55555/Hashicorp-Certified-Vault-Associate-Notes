# Now we can rekey the seal and up the shares and threshold
# First we kick off the process with the -init flag
vault operator rekey -init -key-shares=5 -key-threshold=3

# Now we continue the process by submitting our keys
vault operator rekey

#Finally we can rotate our encryption keys
# But we need to be logged into Vault to do so
vault login

# Let's check on the status of our encryption keys
vault operator key-status

# Now let's rotate the keys
vault operator rotate