# What can we do with the identity engine?
vault path-help identity

# We can create a new entity at the path identity/entity
# It requires a name and nothing else
vault write identity/entity name=ford

# Now we have out entity, next we can create an alias using the entity

# We can create a new alias at the path identity/alias/
# It requires a canonical_id (the id we just got)
# The mount accessor for userpass
# And we have to give the alias a name
mount_accessor=$(vault read sys/auth/ -format=json | jq .data.\"userpass/\".accessor -r)
canonical_id=$(vault read identity/entity/name/ford -format=json | jq .data.id -r)
vault write identity/alias name=fprefect \
  mount_accessor=$mount_accessor \
  canonical_id=$canonical_id

# Lastly, let's create an entity for our local machine that will run
# Vault Agent later
vault write identity/entity name=vaultagent

# We need to get the role-id for the name
role_id=$(vault read auth/approle/role/web-role/role-id -format=json | jq .data.role_id -r)

mount_accessor=$(vault read sys/auth/ -format=json | jq .data.\"approle/\".accessor -r)
canonical_id=$(vault read identity/entity/name/vaultagent -format=json | jq .data.id -r)

vault write identity/alias name=$role_id \
  mount_accessor=$mount_accessor \
  canonical_id=$canonical_id

# Now onto creating an internal group for Arthur and Ford as administrators
vault path-help identity/group

# Looks like we need to give it the following info:
# member_entity_ids
# name

# First we'll get the member entity ids for Ford and Arthur
arthur_id=$(vault read identity/entity/name/arthur -format=json | jq .data.id -r)
ford_id=$(vault read identity/entity/name/ford -format=json | jq .data.id -r)

# Now create the group
vault write identity/group name=vaultadmins \
  member_entity_ids=$arthur_id,$ford_id