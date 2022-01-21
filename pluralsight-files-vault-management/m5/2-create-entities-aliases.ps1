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
$authmethods=$(vault read sys/auth/ -format=json) | ConvertFrom-Json
$mount_accessor=$authmethods.data."userpass/".accessor
$ford_id=$(vault read identity/entity/name/ford -format=json) | ConvertFrom-Json
$canonical_id=$ford_id.data.id
vault write identity/alias name=fprefect mount_accessor=$mount_accessor canonical_id=$canonical_id

# Lastly, let's create an entity for our local machine that will run
# Vault Agent later
vault write identity/entity name=vaultagent

$role_id=$(vault read auth/approle/role/web-role/role-id -format=json) | ConvertFrom-Json

$mount_accessor=$authmethods.data."approle/".accessor
$vaultagent_id=$(vault read identity/entity/name/vaultagent -format=json) | ConvertFrom-Json
$canonical_id=$vaultagent_id.data.id
vault write identity/alias name=$($role_id.data.role_id) mount_accessor=$mount_accessor canonical_id=$canonical_id

# Now onto creating an internal group for Arthur and Ford as administrators
vault path-help identity/group

# Looks like we need to give it the following info:
# member_entity_ids
# name

# First we'll get the member entity id for Arthur
$arthur_id=$(vault read identity/entity/name/arthur -format=json) | ConvertFrom-Json

# Now create the group
vault write identity/group name=vaultadmins member_entity_ids=$($arthur_id.data.id),$($ford_id.data.id)