
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

- *The point is to generate a `Token`, then use this Token to log into vault.*
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
- Enable userpass: `vault auth enable userpass`
- Tune userpass: `vault auth tune -description "My Userpass" userpass/`
- Create userpass user: `vault write auth/userpass/users/<USERNAME> password=<PASSWORD>`


### Auth Method: AppRole

- https://www.vaultproject.io/docs/auth/approle
- Used for machines and apps
- Consists of RoleID (Username) and SecretID (password)
- Vault server push secret ID to the client, or have client hold secretID when it boots up
- Enable AppRole: `vault auth enable approle`
- Tune AppRole: `vault auth tune -description "My AppRole" approle/`
- Create a named role:
	- `vault write auth/approle/<ROLE_NAME> \
		role_name=<ROLE_NAME> \
		secret_id_ttl=<SECRET_ID_TTL> \
		token_num_uses=<TOKEN_NUM_USES> \
		token_ttl=<TOKEN_TTL> \
		token_max_ttl=<TOKEN_MAX_TTL>`
- Fetch the role ID: `vault read auth/approle/role/<ROLE_NAME>/role-id`
- Fetch the secret ID: `vault write auth/approle/role/<ROLE_NAME>/secret-id`

- Logging in with AppRole
	- Information: `vault path-help auth/approle/login`
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









