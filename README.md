
<h1 align="center">Hashicorp Certified Vault Associate Notes</h1>

<h3 align="center">hashicorp.com/certification/vault-associate</h3>


[TOC]

---

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
	- MacOS/Linux: `export VAULT_ADDR='http://127.0.0.1:8200'`
	- Windows: `$env:VAULT_ADDR="http://127.0.0.1:8200"`
4. Login in 
	- `vault login`
	- Set token: Copy from output from `vault server -dev`


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
- References external sources
    - LDAP, GitHub, AWS IAM, etc
- Default auth method
	- Token
	- Cannot disable it
- All auth methods are in `/auth` path

### Auth Method Categories 

- **Cloud Providers:** AWS, Azure, GCP, etc
- **Cloud Native:** Kuberenetes, Cloud Foundry, Github, JWT
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

### Userpass

- For human operators
- Composed of username and password only

### AppRole

- Used for machines and apps
- Consists of RoleID (Username) and SecretID (password)
- Vault server push secret ID to the client, or have client hold secretID when it boots up

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









































