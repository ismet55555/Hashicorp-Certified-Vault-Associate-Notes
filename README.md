
<h1 align="center">Hashicorp Certified Vault Associate Notes</h1>

<h3 align="center">https://www.hashicorp.com/certification/vault-associate</h3>




## Installing Vault

MacOS:
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/vault
```

Ubuntu/Debian:

```bash
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
	sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault
```

## Development Mode

- Running on Localhost
- No SSL - Using HTTP, not HTTPS
- In-memory storage (temporary)
	- In production, you need persistant storage
- Starts unsealed and initialized
- UI enabled
- Key/Value secrets engine enabled

- Start the server `vault server -dev`
- Export the vault server address `export VAULT_ADDR='http://127.0.0.1:8200'`
- Login in `vault login`
	- Set token: Copy from output from `vault server -dev`


## Interacting with Vault

1. CLI
	- General command structure: `vault <command> <subcommand> [options] [ARGUMETNS]`
	- Help menu: `vault <command> --help`
	
	- Getting help with given path: `vault path-help PATH`
2. Browser UI
3. API


- `root` token with root policy can do ANYTHING in vault


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
	1. Navigate to <VAULT HOST>:<PORT>/ui
		- Example: http://127.0.0.1:8200/ui
	2. Enter your token


## Vault API

- RESTful API - Request/Response
- Used by UI and CLI
- Any request tools (ie. curl)
- Need to specify your token for each request
- Example:
	- `curl --header "X-Vault-Token: $root_token" --request GET $VAULT_ADDR/v1/sys/host-info`
