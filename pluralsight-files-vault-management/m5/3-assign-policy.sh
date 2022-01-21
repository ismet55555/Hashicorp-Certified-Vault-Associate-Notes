# Now we are going to assign a policy to an entity and a group
# We'll start by enabling a K/V secrets engine and creating a 
# policy granting access to the engine
vault secrets enable -path=apikeys -version=2 kv

vault policy write read-apikeys read_apikeys.hcl

# Now we can assign that policy to our vaultagent entity
vault write identity/entity/name/vaultagent policies=read-apikeys

# Next we'll create an admin policy and assign it to the vaultadmins group
vault policy write vaultadmins admin-policy.hcl 

vault write identity/group/name/vaultadmins policies=vaultadmins

# Now if we log in with Arthur's account, we will get the vaultadmins policy
vault login -method=userpass username=adent password=arthur