<h1 align="center">Hashicorp Certified Vault Associate Notes</h1>

<h3 align="center">hashicorp.com/certification/vault-associate</h3>

[TOC]

---

## Insert other Notes Here

TODO

## Installing Vault

- Windows

  - `choco install vault`

- MacOS:

  - ```bash
    brew tap hashicorp/tap
    brew install hashicorp/tap/vault
    ```

- Ubuntu/Debian:
  - ```bash
      curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
      sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install vault
    ```

## Development Mode

- Running on Localhost
- No SSL - Using HTTP, not HTTPS
- In-memory storage
  - Temporary - Once server stops, everything is gone
    - In production, you need persistent storage / Backend
- Starts unsealed and initialized
- UI enabled
- Key/Value secrets engine enabled

### Setting up development mode server

1. Start the development vault server
   - `vault server -dev`
2. Open another terminal window
3. Export the vault server address
   - MacOS/Linux/WSL: `export VAULT_ADDR='http://127.0.0.1:8200'`
   - Windows: `$env:VAULT_ADDR="http://127.0.0.1:8200"`
4. Login in
   - `vault login`
   - Set token: Copy from output from `vault server -dev` output

## Interacting with Vault

1. CLI

   - General command structure: `vault <command> <subcommand> [options] [ARGUMETNS]`
   - Help menu: `vault <command> --help`

   - Getting help with given path: `vault path-help PATH`

2. Browser UI
3. API

!!! danger `root` token with root policy can do ANYTHING in vault

## Environment Variables

- All vault environment variables are prefixed with `VAULT_`

  - `VAULT_ADDR` - Vault server address
  - `VAULT_TOKEN` - Vault token for requests
  - `VAULT_SKIP_VERIFY` - Skip SSL verification. No verify TLS certificate.
    - Useful for self-signed certificates / Dev environment
  - `VAULT_FORMAT` - Output format. Default is JSON.
    - JSON
    - YAML
    - TOML
  - `VAULT_UNSEAL_KEY` - Unseal key for vault

- If server address not specified:
  `Error checking seal status: Get "https://127.0.0.1:8200/v1/sys/seal-status": http: server gave HTTP response to HTTPS client`

## Vault UI

- Uses API on backend (as everything else that interacts with vault)
- Not enabled by default
- Runs on the same port as API
- Basic console withing the UI for basic vault commands
- Getting to the UI
  1. Navigate to `<VAULT HOST>:<PORT>/ui`
     - Example: http://127.0.0.1:8200/ui
  2. Enter your token

## Vault API

- RESTful API - Request/Response
- Used by UI and CLI
- Any request tools (ie. curl)
- Need to specify your token for each request
- Example:
  - `curl --header "X-Vault-Token: $root_token" --request GET $VAULT_ADDR/v1/sys/host-info`

## Authentication Methods

- _The point is to generate a `Token`, then use this Token to log into vault._
- Provided by plug-ins with binary
- Can enable multiple auth methods
  - Can also enable multiple instances for multiple auth methods
- References **external** sources
  - LDAP, GitHub, AWS IAM, etc
- Default auth method
  - Token
  - Cannot disable it
- All auth methods are in `/auth` path

### Auth Method Categories

- **Cloud Providers:** AWS, Azure, GCP, etc
- **Cloud Native:** Kubernetes, Cloud Foundry, Github, JWT
- **Traditional:** LDAP, RADIUS, Kerberos, etc
- **Vault Native (Internal):** Token, AppRole, Userpass

### Choosing Auth Method

- Who is going to acces Vault?
  - External/Internal
  - Human/Machine
- How are they going to access it?
- What do they use today?
  - GitHub Accounts
  - Active directory
  - Certificates
- See which suits the client and environment

### Auth Method: Userpass

- https://www.vaultproject.io/docs/auth/userpass
- For human operators
- Composed of username and password only
- Enable userpass:
  - `vault auth enable userpass`
- Tune userpass:
  - `vault auth tune -description "My Userpass" userpass/`
- Create userpass user:
  - `vault write auth/userpass/users/<USERNAME> password=<PASSWORD>`

### Auth Method: AppRole

- https://www.vaultproject.io/docs/auth/approle
- Used for machines and apps
- Consists of RoleID (Username) and SecretID (password)
- Vault server push secret ID to the client, or have client hold secretID when it boots up
- Enable AppRole:
  - `vault auth enable approle`
- Tune AppRole:
  - `vault auth tune -description "My AppRole" approle/`
- Create a named role:

  - ```
    vault write auth/approle/<ROLE_NAME> \
    		role_name=<ROLE_NAME> \
    		secret_id_ttl=<SECRET_ID_TTL> \
    		token_num_uses=<TOKEN_NUM_USES> \
    		token_ttl=<TOKEN_TTL> \
    		token_max_ttl=<TOKEN_MAX_TTL>
    ```

- Logging in with AppRole
  - Information:
    - `vault path-help auth/approle/login`
  - Generating Vault Client Token
    - Need `role_id`
      - `vault read auth/approle/role/<ROLE_NAME>/role-id`
    - Need `secret_id`
      - `vault write auth/approle/role/<ROLE_NAME>/secret-id`
      - Note the `write`, this generates data
      - Generated on the fly, or can specify the `secret_id`
      - This yields `secret_id`, `secret_id_accessor`, and `secret_id_ttl`
    - Using CLI:
      - `vault write auth/approle/login role_id=<ROLE_ID> secret_id=<SECRET_ID>`
      - This yields a token and its information
    - Using REST API
      - POST to `<VAULT_ADDR>/v1/auth/approle/login`
      - Passed data includes `role_id` and `secret_id`

### Auth Method: AWS

TODO

!!! tip Exam Tip
Exam will cover choosing the correct auth method for a given scenario

### Configuration

- All methods are enabled on `/sys/auth`
- All methods are enabled on a path
  - If not specified, default to method name
- Methods cannot be moved after they are set on a path
- Once enabled, can be tuned and configured
  - **Tunning:** Common for all methods
  - **Configuration:** Specific to each method (in `/sys/auth/<method>/config`)

### Basic Commands

- List Existing:
  - `vault auth list`
- List Available Options:
  - `vault path-help auth/<AUTH METHOD NAME>`
- Enable:
  - `vault auth enable [options] TYPE`
  - Enable with custom path: `vault auth enable -path=globopass userpass`
  - Enable userpass: `vault auth enable userpass`
- Tune:
  - `vault auth tune [options] PATH`
  - Example: `vault auth tune -description="First userpass" globopass/`
- Disable:
  - Will remove all info stored by this auth method
  - `vault auth disable [options] PATH`

### Using Auth Method

- CLI, UI, or API
- `vault login`
  - For interactive methods view user
  - Will result in token and token information
  - `vault login`
    - Will prompt for token
  - `vault login [options] [AUTH METHOD KEY-VALUE PAIRS]`
    - Depends on the auth method used
    - Example: `vault login userpass username=<USERNAME> password=<PASSWORD>`
- `vault write`
  - For any other method (AppRole, LDAP, etc)
  - `vault write [options] PATH [KEY-VALUE PAIRS]`
    - Depends on the auth method used
    - Example: `vault write auth/userpass/login/ismet password=<PASSWORD>`

!!! tip
Using CLI: `vault auth`
Interacting with auth methods: `vault login` or `vault write`

### Disable Auth Method

- `vault auth disable [options] PATH`
  - Example: `vault auth disable approle/`
  - Note that we did not have to spacify path (auth/approle), since we are using `auth`

## Vault Policies

- As everything, policies are path based
- Grant or forbid access to certain paths and operations (what you can do in Vault)
- Policies are `deny` by default (Empty policy)
- Policies are assigned to tokens, identity, or auth method

- Define permissions (Access Control Lists (ACL))
- No internal versioning of policies
  - Make you back up some other way

### Root Policy

- Can do ANYTHING
- Careful who gets assigned this policy!

### Default Policy

- Allow tokens to look up their own properties
  - `path "auth/token/lookup-self" { ... }`
- Allow tokens to renew themselves
  - `path "auth/token/renew-self" { ... }`
- Allow tokens to revoke themselves
  - `path "auth/token/revoke-self" { ... }`
- Allow tokens to look up its own capabilities on a path
  - `path "sys/capabilities-self" { ... }`
- Allow a token to look up its own entity by id or name
  - `path "identity/entity/id/{{identity.entity.id}}" { ... }`

### Policy Syntax

- HCL (preferred) or JSON
- Policy Path: Where the policy is applied
- Policy Capabilities: What acations are allowed
- Basic path expression:
  - `path "some-path/in/valut"`
- Two wildcards:
  1.  glob `*`
      - Added at the END of a path, matches extension of path (This is not RegEx)
      - Example: `path "some-path/*"` -> `path "some-path/something"` and `path "some-path/something/else"`
  2.  segment `+`
      - Placeholder WITHIN a path, matches any number of characters
      - Example: `path "secrets/+/blah"` -> `path "secrets/something/blah"` and `path "secrets/cool/blah"`
  - **NOTE:** `"secret/foo"` would only address `secret/foo`, and nothing under it

#### Examples

- Example: Grant read access to secret `secret/foo`
  - ```hcl
    path "secret/foo" {
    	capabilities = ["read", "list"]
    }
    ```
- Wildcard `*` addresses all downstream paths
  - Example: Grant read access to all secrets
  - ```hcl
    path "secret/*" {
    	capabilities = ["read", "list"]
    }
    ```
- Note that any sub path can be overridden by setting a policy:
  - ```hcl
    path "secret/super-secret" {
    	capabilities = ["deny"]
    }
    ```
- Policies rules can be set up to allow, disallow, or require policy parameters
  - Example: `secret/restricted` can only contain any value for `foo`, and `zip` or `zap` for `bar`
  - ```hcl
    path "secret/restricted" {
    	capabilities = ["create"]
    	allowed_parameters = {
    		"foo" = []
    		"bar" = ["zip", "zap"]
    	}
    }
    ```
- Can use "glob" patterns / wildcard to match paths
  - Example: `secret/foo/*` will match `secret/foo/bar`
  - ```hcl
    path "secret/foo/*" {
    	capabilities = ["read", "list"]
    }
    ```
- Any number of characters that are bounded withing a single path segment, use `+`
  - Example: Permit reading `secret/foo/bar/teamb`, `secret/bar/foo/teamb`, etc.
  - ```hcl
    path "secret/+/+/teamb" {
    	capabilities = ["read"]
    }
    ```

### Templated Policies (Parameters)

- Dynamic way of defining paths in policies
- Using `{{ }}` to let vault know that you are adding a parameter, then adding the path to the parameter
  - Example: Resolve the name of the entity
    - `path "secret/{{identity.entity.name}}/*" { ... }`
- **NOTE:** Currently, the only source for parameters is `identity` secrets engine

### Capabilities

- Follows CRUD semantics (Create, Read, Update, Delete)
  - `create` - Creating data at the given path (similar to `update`, which is also `POST/PUT` call)
  - `read` - Reading data at the given path
  - `update` - Changing data at given path
  - `delete` - Deleting data at given path
- Additional capabilities:
  - `list` - Listing data at given path. No access to key data.
  - `sudo` - Access to paths that are _root-protected_
  - `deny` - Disallow access to given path. Overrides any other action.

### Policy Rules

- Policy that Vault applies are determined by the most-specific match available
- If same pattern appears in multiple policies, the union of both is taken
  - Example: Combine `[read, list]` with `[create]`
- If different patterns appear in multiple policies, the highest-precedence one is taken

### Working with Policies

- List existing policies
  - `vault policy list`
- Read the contents of a policy
  - `vault policy read [OPTIONS] [POLICY NAME]`
    - Example: `vault policy read secrets-mgmt`
- Write a new policy or update an existing policy
  l. `vault policy write [OPTIONS] [POLICY NAME] [POLICY FILE]` - Example: `vault policy write secrets-mgmt policy.hcl` 2. `vault policy write [OPTIONS] [POLICY NAME] -` - Example: `cat policy.hcl | vault policy write secrets-mgmt -`
- Delete a policy
  - `vault policy delete [OPTIONS] [POLICY NAME]`
    - Example: `vault policy delete secrets-mgmt`
- Format the policy (more readable syntx)
  - `vault policy fmt [OPTIONS] [POLICY FILE]`
    - Example: `vault policy fmt policy.hcl`

### Assigning Policies

The policy has to already be created and active in Vault to be assigned.

1. Associate directly with a token
   - Assign a policy at token creation
   - Example: `vault token create -policy=secrets-mgmt`
2. Assign to a user in userpass
   - Example: `vault write auth/userpass/users/ismet token_policies="secrets-mgmt"`
3. Assign to an entity in identity secrets engine
   - Example: `vault write identity/entity/name/ned policies="secrets-mgmt"`

### Parameter Constraints

Vault policies can be further restricted

1. `required_parameters` - List of parameters that must be set
   - **Example**: Requires users to create `secret/foo` with "bar" and "baz"
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	required_parameters = ["bar", "baz"]
       }
       ```
2. `allowed_parameters` - Keys and values taht are permitted on the given path

   - **Example**: Allows users to create `secret/foo` with ONLY "bar" with "bar" containing ANY value
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	allowed_parameters = {
       		"bar" = []
       	}
       }
       ```
   - **Example**: Allows users to create `secret/foo` with ONLY "bar" with "bar" containing ONLY "zip" and "zap"
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	allowed_parameters = {
       		"bar" = ["zip", "zap"]
       	}
       }
       ```
   - **Example**: Allows users to create `secret/foo` with any key and value, but if user creates "bar", it must be "zip" or "zap"
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	allowed_parameters = {
       		"bar" = ["zip", "zap"]
       		"*" = []
       	}
       }
       ```

3. `denied_parameters` - Blacklist of parameters and values (Supersedes `allowed_parameters`)
   - **Example**: Allows users to create "secret/foo" with any parameter but not named "bar"
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	denied_parameters = {
       		"bar" = []
       	}
       }
       ```
   - **Example**: Allows users to create "secret/foo" with parameter named "bar", which cannot contain "zip" or "zap"
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	denied_parameters = {
       		"bar" = ["zip", "zap"]
       	}
       }
       ```

### Require Response Wrapping TTLs (Time to Live)

- See: https://www.vaultproject.io/docs/concepts/policies#required-response-wrapping-ttls

## Tokens

- Authentication within Vault
- Tokens are a collection of data used to access Vault
- Used directly or via auth methods (dynamically generated)
- Tokens are mapped to policies and metadata for auditing purposes

### Creating Tokens

Tokens can be created in the following ways:

1. **Auth method** - Tokens are generated by an auth method
2. **Parent token** - Use existing token to generate a child token
3. **Root token** - Requires a special process to generate
   - Can do ANYTHING
   - Does not expire
   - Created:
     1. Initialize Vault server
     2. Existing root token
     3. Using `operator` command
   - _Revoke it as soon as possible / As soon as action is completed_
   - Why create a root token?
     1. Perform initial vault setup
     2. If main auth method is not available
     3. Emergency situation where root token is needed

### Token Properties

- `id` - Unique token ID
- `accessor` - A value to use lookup the token, without needing to use it
- `type` - What type of token it is, "service" or "batch"
- `policies` - List of policies that the token is allowed to access
- `ttl` - Time to live of the token. How long will it be valid for.
- `orphaned` - Whether the token has a parent token or is a stand-alone

### Token Accessor

- Only able to view token properties, cannot retrieve the ID of the token
- View capabilities on a given path
- Used to renew or revoke a token
- Some situation you may need it:
  - Something may only need ability to revoke a token and check status of child tokens
  - View list of all tokens issued, like in `auth/token/accessors`
  - Audit token usage by accessor in audit log. ID won't be seen

### Working with Tokens

- Create a new token
  - `vault token create [OPTIONS]`
    - Example: `vault token create -policy=my-policy -ttl=60m`
- View token properties
  - `vault token lookup [OPTIONS] [ACCESSOR or ID]`
    - Example: `vault token lookup -accessor=FJKD0870sdfjlhjsdf07sdfY`
  - Can also view your own token
    - `vault token lookup`
- Check capabilities/permissions for a specific path
  - `vault token capabilities TOKEN PATH`
    - Example: `vault token capabilities x.TG08098SLDLFHlsdhflsdhSDFI secret/foo`
- Renew a token
  - `vault token renew [OPTIONS] [ACCESSOR or ID]`
    - Example: `vault token renew -increment=30m -accessor=FJKD0870sdfjlhjsdf07sdfY`
- Revoke a token
  - `vault token revoke [OPTIONS] [ACCESSOR or ID]`
    - Example: `vault token revoke -accessor=FJKD0870sdfjlhjsdf07sdfY`

### Token Types

1. Type Type: **Service**

   - Default type of token for most situations
   - Fully featured
   - Heavyweight
   - Has to written to storage backend
   - Can be managed via token accessor or token ID
   - Root and periodic tokens are service tokens
   - Calculated lifetime based on token TTL or any renewals for that token
   - Can create child tokens
   - Begins with **"s."** in token ID

2. Token Type: **Batch**

   - Not default, must be explicitly created
   - Limited features
   - Lightweight
   - Not written to persistent storage backend
   - Has no token accessor (metadata)
   - Static lifetime - Once created and TTL set, cannot be renewed
   - Has no child tokens
   - Begins with **"b."** in token ID
   - Example:
     - Create: `vault token create -type=batch -policy=default -ttl=30m`

3. Token Type: **Periodic**
   - Is also a service token
   - Not default, must be explicitly created
   - Can be renewed indefinitely, does not expire, no max TTL
   - TTL is set to period at creation and renewals
   - Requires root (`sudo`) privileges to create
   - Renewals cannot exceed what has been provided by `-period`
   - Example:
     - Create: `vault token create -policy=default -period=2h`
     - Renew: `vault token renew -increment=60m s.YvR0cqzXsDDdCne0w28QZ4kr`

### Token Lifetime

- TTL (Time to Live) - How long the token is valid for
- Max TTL - How long can the token be valid before it cannot be renewed anymore
- Token TTL properties
  - `creation_time` - When the token was created
  - `creation_ttl` - The TTL set when the token was created
  - `expire_time` - When the token will expire (predicted, if nothing changes)
  - `explicit_max_ttl` - The max TTL set when the token was created, cannot be exceeded
  - `issue_time` - When the token was issued
  - `TTL` - Current value of TTL

#### Working with Token Lifetime

- Renew a token
  - `vault token renew [OPTIONS] [ACCESSOR or ID] [ -increment=<DURATION> ]
    - Example: Extend the currently active token by 30 minutes
      - `vault token renew -increment=30m`
    - Example: Extend another token by 30 minutes
      - `vault token renew -increment=30m -accessor=FJKD0870sdfjlhjsdf07sdfY`
- Revoke a token
  - `vault token revoke [OPTIONS] [ACCESSOR or ID]`
    - Example: Revoke the currently active token
      - `vault token revoke -self`
    - Example: Revoke another token
      - `vault token revoke -accessor=FJKD0870sdfjlhjsdf07sdfY`

#### Setting Maximum Token TTL

> **Note:** Default max TTL is 32 days

1. System max TTL

   - System-wide setting for maximum TTL
   - Defined within Vault configuration file
   - Dynamically evaluated (will check against it constantly)
   - Example:
     - `vault server -config /etc/vault/config.hcl`

2. Mount max TTL for specific auth method

   - Mount specific
   - Change with `vault auth tune` command
   - Will override system max TTL
   - Can be greater or less than system max TTL
   - Examples:
     - `vault auth enable -max-lease-ttl=776h userpass/`
     - `vault auth tune -max-lease-ttl=72h`

3. Auth method max TTL for objects within auth method
   - Set max TTL for role, group, user, etc.
   - Change with `write` command
   - Overrides system and mount max TTL
   - MUST be less than system and mount max TTL
   - Example:
     - `vault write auth/userpass/users/ismet max-lease-ttl=72h`
     - `vault write auth/userpass/users/bob token-max-ttl=72h password=sEcReT`

## Secrets Engines

**Docs:** https://www.vaultproject.io/docs/secrets

- Plugins used by Vault to handle sensitive data
- Store, generate, or encrypt data
- Broad categories: **Dynamic** and **Static**
- General Secrets engine categories:
	- **Cloud** - AWS, Azure, GCP, etc.
	- **Database** - MSSQL, PostgreSQL, MySQL, etc.
	- **Internal** - Key/Value, Identity, Transit, etc.
	- **Identity** - Active Directory, LDAP, etc.
	- **Certificate** - SSH, PKI, etc.
	- **Tokens** - Consul, Nomad 

> **Note:** Secret engine specifics are not needed for the certification exam, only how to generally use them.

### Identity Engine

**Docs:** https://www.vaultproject.io/docs/secrets/identity

- Maintains clients who are recognized by Vault
- "Clients" are users or applications that have been authenticated by Vault
- Identity engine tracks those clients internally within Vault
- Enabled by default
- Cannot be disabled or moved
- Cannot enable multiple instances/paths of the identity engines
- Each client is a `Entity`
	- Entry within the identity engine that represents a client
- Any entity can have multiple `Aliases`
	- For example, a single user who has accounts in both GitHub and LDAP, 
	can be mapped to a  single entity in Vault that has 2 aliases, one 
	of type GitHub and one of type LDAP.
- Can place entities in different groups to manage policy assignments to entities


### Cubbyhole Engine

**Docs:** https://www.vaultproject.io/docs/secrets/cubbyhole 

- Stores arbitrary secrets within Vault, namespaced to a token
- Paths are scoped per token
- No token can access other token's cubbyhole path
- Each cubby inside the cubby hole is created per service token
- Cubby is only accessible by that token
- Enabled by default
- Cannot be disabled or moved
- No versioning for secrets
- **The root token has no access to the cubbyhole, only its token can access it**
- Usage:
	- Write: `vault write cubbyhole/my-secret my-value=s3cr3t`
	- Read: `vault read cubbyhole/my-secret`
	- API: Reading via curl
		- ```bash
			curl \
				--header "X-Vault-Token: <TOKEN HERE>" \
				http://127.0.0.1:8200/v1/cubbyhole/my-secret
			```


### Types of Secrets

- **Static secrets**
	- Store existing data securely
	- You already have this data, and Vault needs to manage it and access to it
	- Manual lifecycle management
	- Manually load new versions of secret to a secret engine
	- Example:
		- Key/Value secret engine

- **Dynamic Secrets**
	- Generated data on demand
	- Lease issued for each secret (TTL)
	- Automatic lifecycle management 
	- Majority of secrets engines are dynamic















## System Backend

- System Backend is mounted at `/sys`
- Cannot be disabled or moved
- List of available system backends can be seen here: https://www.vaultproject.io/api-docs/system
- Examples
  - `/sys/mounts` - Used to manage secrets engines in Vault
  - `/sys/monitor` - Used to receive streaming logs from the Vault server
  - `/sys/audit` - Used to list, enable, and disable audit devices
