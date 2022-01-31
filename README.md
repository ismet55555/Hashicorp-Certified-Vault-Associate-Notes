<p align="center"><img width="150" alt="portfolio_view" src="logo.png"></p>

<h1 align="center">Hashicorp Certified Vault Associate Notes</h1>
<h4 align="center"><a href="https://www.hashicorp.com/certification/vault-associate">hashicorp.com/certification/vault-associate</a></h3>

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Exam Overview](#exam-overview)
  - [General Objectives](#general-objectives)
- [Vault Architecture](#vault-architecture)
- [High Availability (Cluster)](#high-availability-cluster)
  - [Networking](#networking)
  - [Vault Replication](#vault-replication)
- [Vault Setup](#vault-setup)
  - [Installing Vault](#installing-vault)
    - [Package Manager](#package-manager)
    - [Binary Download](#binary-download)
  - [Configuring Vault](#configuring-vault)
    - [Configuration File Categories and Parameters](#configuration-file-categories-and-parameters)
  - [Server Initialization and Unseal](#server-initialization-and-unseal)
  - [Seal/Unseal](#sealunseal)
    - [Vault Encryption keys](#vault-encryption-keys)
    - [Vault Seal Options](#vault-seal-options)
  - [Key Management](#key-management)
  - [Development Mode](#development-mode)
- [Interacting with Vault](#interacting-with-vault)
- [Environmental Variables](#environmental-variables)
- [Vault UI](#vault-ui)
- [Vault API](#vault-api)
- [Authentication Methods](#authentication-methods)
  - [Auth Method Categories](#auth-method-categories)
  - [Choosing Auth Method](#choosing-auth-method)
  - [Auth Method: Userpass](#auth-method-userpass)
  - [Auth Method: AppRole](#auth-method-approle)
  - [Auth Method: AWS](#auth-method-aws)
  - [Configuration](#configuration)
  - [Basic Commands](#basic-commands)
  - [Authenticating (Logging in)](#authenticating-logging-in)
  - [Disable Auth Method](#disable-auth-method)
- [Vault Policies](#vault-policies)
  - [`root` Policy](#root-policy)
  - [`default` Policy](#default-policy)
  - [Policy Syntax](#policy-syntax)
    - [Examples](#examples)
  - [Templated Policies (Dynamic Parameters)](#templated-policies-dynamic-parameters)
  - [Policy Capabilities](#policy-capabilities)
  - [Policy Evaluation Rules](#policy-evaluation-rules)
  - [Working with Policies](#working-with-policies)
  - [Assigning Policies](#assigning-policies)
  - [Parameter Constraints](#parameter-constraints)
- [Tokens](#tokens)
  - [Creating Tokens](#creating-tokens)
  - [Token Properties](#token-properties)
  - [Token Accessor](#token-accessor)
  - [Working with Tokens](#working-with-tokens)
  - [Token Types](#token-types)
  - [Token Lifetime](#token-lifetime)
    - [Working with Token Lifetime](#working-with-token-lifetime)
    - [Setting Maximum Token TTL](#setting-maximum-token-ttl)
- [Secrets Engines](#secrets-engines)
  - [Types of Secrets](#types-of-secrets)
  - [Working with Secrets Engines](#working-with-secrets-engines)
  - [Response Wrapping](#response-wrapping)
  - [Secrets Engine: Cubbyhole](#secrets-engine-cubbyhole)
  - [Secrets Engine: Identity](#secrets-engine-identity)
  - [Secret Engine: Database](#secret-engine-database)
  - [Secret Engine: Key Value (KV)](#secret-engine-key-value-kv)
  - [Secret Engine: Transit](#secret-engine-transit)
    - [Working with Transit Engine](#working-with-transit-engine)
- [Leases](#leases)
  - [Working with Leases](#working-with-leases)
- [Vault Agent](#vault-agent)
  - [Auto-Auth](#auto-auth)
  - [Caching](#caching)
  - [Templates](#templates)
- [System Backend](#system-backend)

<!-- /code_chunk_output -->

## Exam Overview

**Docs:** https://www.hashicorp.com/certification/vault-associate

- Beginner or intermediate knowledge level
- Do not really need production experience
- Working with development is ok
- Online proctored
- 60 questions
- 60 minutes
- Certification lasts 2 years
- Type of questions
  - Multiple Choice
  - Fill in the blank
  - Hotspot - click on graphic

### General Objectives

Know the following at an *associate* level, not a deep detailed level.

1. Compare authentication methods
2. Create Vault policies
3. Assess Vault tokens
4. Manage Vault leases
5. Compare and configure Vault secrets engines
6. Utilize Vault CLI
7. Utilize Vault UI
8. Be aware of the Vault API
9. Explain Vault architecture
10. Explain encryption as a service




## Vault Architecture

Conceptual:

- Clients -> API -> Vault -> Backend
- Backend
  - Authentication
  - Policies
  - Secrets Engines
  - Audit Logging
- Frontend
  - Clients (CLI, SDK, etc) -> API -> Vault
  - Clients use Vault tokens to do things

Logical:

- Vault creates a barrier
- Anything entering the barrier is encrypted
- On frontend API communication with Vault is with TLS Certificate
- On backend Vault stores to backend storage, this is also encrypted through encryption keys
- API -> Barrier -> Vault -> Barrier -> Storage

## High Availability (Cluster)

**Docs:** https://www.vaultproject.io/docs/internals/high-availability

- One active and many standby nodes
- Active node processes client requests

### Networking

- Passive nodes forward or redirect requests to active node for processing
- Read-only nodes _(Enterprise only)_
  - Read or list - Something that doesn't modify backend storage
- One single node is elected as the leader (active) node

  - Leader node places a write lock on the backend storage (if lock supported by backend)

- Cluster configurations
  - **Docs:**: https://www.vaultproject.io/docs/configuration#high-availability-parameters
  - Set in the vault config file
  - `cluster_address`
    - Which IP/host address to listen on for cluster based communication
    - Example
      - ```hcl
        listener "tcp" {
          address = 10.1.1.1:8200           # <-- Listen for vault client requests
          cluster_address = 10.1.1.1:8201   # <-- Listen for cluster-based communication
        }
        ```
  - `cluster_addr`
    - The URL that the node will hand out for cluster for request forwarding.
    - Example: For active server node (server1)
      - ```hcl
        cluster_addr = "https://server1:8201"  # <-- URL for cluster communication coming in
        ```
  - `api_addr`
    - URL that that the node hands out for cluster for vault client request forwarding
    - Example: For standby server node (server2)
      - ```hcl
        api_addr = "https://server2:8200"      # <-- URL for API requests to Vault server
        ```
- Client request handling
  1. **Request Forwarding (default)**
     - Client talks to standby server (or any available server)
     - The standby server talks to active (leader) server in the background
     - The standby server responds to client
     - Client never knows that the request has been internally forwarded to active node
  2. **Client Redirection**
     - Client request is redirected to the active node
     - Client talks directly to active node directly
  3. **Load Balancer**
     - Client sends request to load balancer, load balancer resolves the request to the active node
     - **HashiCorp recommends not use a load balancer**

### Vault Replication

**Docs:** https://www.vaultproject.io/docs/internals/replication

- Enterprise only feature!
- Unit of replication is the cluster
  - Primary cluster replicates data to secondary clusters
  - Replication is one-to-many
- Replication is asynchronous
- Replication Options
  - **Disaster recovery**
    - Replicates data, tokens, and leases - Immediately available
    - Only there for disaster recovery, cannot take requests
  - **Performance**
    - Replicates data only (not tokens or leases)
    - Clients in secondary site for this cluster need to generate their own tokens and leases
      to talk to this secondary cluster
    - Allows read-only requests to replicated vault data
    - Data modification request is forwarded to primary cluster
- Can have one disaster recovery cluster and one performance cluster at the same time

## Vault Setup

### Installing Vault

**Docs:** https://learn.hashicorp.com/tutorials/vault/getting-started-install

Installing vault is essentially getting the vault binary file onto your computer.

#### Package Manager

- **Windows**

  - ```psh
    choco install vault
    ```

- **MacOS**

  - ```bash
    brew tap hashicorp/tap
    brew install hashicorp/tap/vault
    ```

- **Ubuntu/Debian**
  - ```bash
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install vault
    ```

#### Binary Download

1. Download the binary for your platform/architecture
   - https://www.vaultproject.io/downloads
   - Unzip/Extract
     - Linux/MacOS: `unzip vault_1.9.3.zip`
     - Windows: `Expand-Archive vault_1.9.3.zip`
2. Move the binary to a directory that is listed on PATH environmental variable
    - To show the PATH environmental variable
      - Linux/MacOS: `echo $PATH`
      - Windows: `echo $env:path`

### Configuring Vault

**Docs:** https://www.vaultproject.io/docs/configuration

This is performed after vault has been installed and the `vault` command can be used

- Vault server configuration is set using a Hashicorp Configuration Langurage (HCL) or JSON file
- This config file is set using `-config` flag when setting up valut
  - `vault server -config=my_config.hcl`

#### Configuration File Categories and Parameters

- **General**
  - Any info not in any configuration block
  - `ui = true`
    - Enable/Disable Vault Web UI
    - Is `false` by default
  - `disable_mlock = false`
    - Enable/Disable: Prevent data in memory to be written to swap storage
    - Set to `true` if using integrated storage (raft)
  - `cluster_addr = "https://vault.example.com:8200"`
    - Address of the Vault cluster for general usage
  - `api_addr = "https://vault.example.com:8200"`
    - Address of the Vault API given to clients
- **High Availability / Replication**
  - Options for cluster scenario
  - ```hcl
    replication { ... }
     ```
- **Listener**
  - How vault server will listen for incoming requests from clients and other cluster members
  - Example: Local loopback address
    - ```hcl
      listener "tcp" {
        address = "127.0.0.1:8200"          # <-- Listen for requests on this address
        cluster_address = "127.0.0.1:8201"  # <-- Listen for cluster communication
        tls_cert_file = "public/cert.crt"   # <-- TLS certificate for secure communication
        tls_key_file = "private/cert.key"   # <-- TLS private key for secure communication
      }
      ```
- **Seal (Optional)**
  - How vault seal is configured
  - Only used for _auto-unseal_ functionality, not needed for shamir secret key sharing
  - Example: Unseal using AWS KMS service
    - ```hcl
      seal "awskms" {
        region     = "us-east-1"
        kms_key_id = "19ec80b0-dfdd-4d97-8164-c6examplekey"
        endpoint   = "https://vpce-0e1bb1852241f8cc6-pzi0do8n.kms.us-east-1.vpce.amazonaws.com"
        access_key = "AKIAIOSFODNN7EXAMPLE"
        secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      }
      ```
- **Telemetry**
  - What performance and health info to send from valut server to monitoring system
  - Can have one or more nested blocks within it for different telemetry data or target
  - Example: Prometheus
    - ```hcl
      telemetry {
        disable_hostname = true
        prometheus_retention_time = "168h"
      }
      ```
- **Storage**
  - Storage backend used by vault server to store its data
  - Note: Can only have one storage backend
  - Example: Local disk storage
    - ```hcl
      storage "file" {
        path = "/mnt/vault/data"
      }
      ```
  - Example: AWS S3 storage
    - ```hcl
      storage "s3" {
        region = "us-east-1"
        bucket = "vault-server-data"
        access_key = "AKIAIOSFODNN7EXAMPLE"
        secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
      }
      ```
  - Example: Integrated Storage (Raft) - Cluster setup
    - ```hcl
      storage "raft" {
        path = "/path/to/raft/data"  # <-- Path to locally store raft data
        node_id = "node_1"           # <-- Unique for each cluster node
        retry_join {
          leader_api_addr = "https://node1.vault.local:8200"
          ... <MORE> ...
        }
        retry_join {     # <-- A block for each member of the cluster
          ... <MORE> ...
        }
      }
      ```

### Server Initialization and Unseal

This is performed after vault has been _installed_ and the server has been _configured_.
At this point vault is not initialized and is sealed

- **Get Vault Server Status**
  - `vault status`
  - Will show if vault is sealed and/or initialized
  - _Example Output:_ Status of a sealed and not initialized vault server
    - ```text
      Key                Value
      ---                -----
      Seal Type          shamir
      Initialized        false       <-- Vault is not initialized
      Sealed             true        <-- Vault is sealed
      Total Shares       0
      Threshold          0
      Unseal Progress    0/0         <-- No key shares applied
      Unseal Nonce       n/a
      Version            1.6.3
      Storage Type       raft
      HA Enabled         true
      ```
- **Initialize Vault Server**

  - **Docs:** https://www.vaultproject.io/docs/commands/operator
  - `vault operator init [OPTIONS]`
  - Defaults to 5 key shares, with 3 key shares required to unseal
  - _Example:_ Use Shamir secret sharing with specified key shares

    - `vault operator init -key-shares=3 -key-threshold=2`
    - _Example Output:_

      - ```text
        Unseal Key 1: zCku4j3Q2WoiEMze0mvpbf98VOAVOfTxcNbvweJiR0NL
        Unseal Key 2: J8iBqZ8SSQsUvYFA/EOra4h22cGrmuZicKXfA3Nj32xd
        Unseal Key 3: SjYlN0OfH8DANm7b9zkTGlHllJ323KqBcCJ6jr/5Nf1P

        Initial Root Token: s.9BampfHGQIc5nhVPGlp63hXT

        Vault initialized with 3 key shares and a key threshold of 2. Please ...
        ```

  - _Example:_ Using auto-unseal
    - `vault operator init -recovery-share=5 -recovery-threshold=3`

- **Unseal Vault Server**

  - **Docs:** https://www.vaultproject.io/docs/commands/operator/unseal
  - `vault operator unseal [OPTIONS] [KEY]`
  - This is performed after the server has been initialized
  - More than one person running this command separately from separate terminals, targeting the same valut server address
  - Can also be done using the vault server UI via web browser
  - _Example Output:_ Entering 2 of 3 unseal keys to unseal vault

    - ```text
      ismet:~$ vault operator unseal
      Unseal Key (will be hidden): <HIDDEN INPUT VIA TERMINAL>
      Key                Value
      ---                -----
      Seal Type          shamir
      Initialized        true                  <-- Vault is initialized
      Sealed             true                  <-- Still sealed
      Total Shares       3
      Threshold          2
      Unseal Progress    1/2                   <-- Note the unseal progress
      Unseal Nonce       3d24a0fa-edd ...
      Version            1.6.3
      Storage Type       raft
      HA Enabled         true

      ismet:~$ vault operator unseal
      Unseal Key (will be hidden):  <HIDDEN INPUT VIA TERMINAL>
      Key                     Value
      ---                     -----
      Seal Type               shamir
      Initialized             true
      Sealed                  false            <-- Finally unsealed
      Total Shares            3
      Threshold               2
      Version                 1.6.3
      Storage Type            raft
      Cluster Name            vault-cluster-39615fe5
      Cluster ID              59f91aa5-65d ...
      HA Enabled              true
      HA Cluster              n/a
      HA Mode                 standby
      Active Node Address     <none>
      Raft Committed Index    24
      Raft Applied Index      24
      ```

- **Seal Vault Server**
  - `vault operator seal [OPTIONS]`
  - Only requires one single operator
  - Requires root/sudo privileges
  - Vault server will be unusable until unsealed

### Seal/Unseal

**Docs:** https://www.vaultproject.io/docs/concepts/seal#seal-unseal

- Vault starts in a sealed state, it doesn't know how to decrypt anything
- Unsealing Vault provides encryption key to decrypt all data

#### Vault Encryption keys

- **Encryption keys (keyring)**
  - Protects/Encrypts data written to storage backend
  - Actively used on data
  - Stored on disk to storage backend
- **Master key**
  - Protects/Encrypts the encryption keys (keyring)
  - Stored on disk to storage backend
- **Unseal key**
  - Protects/Encrypts the master key
  - Stored as **key shares** or on external service or device with multiple individuals
  - Can be divided up in multiple keys, entered separately by different users
  - _Never stored by Vault_

> **Summary:** Vault data is encrypted using the encryption key in the keyring; the keyring
> is encrypted by the master key; and the master key is encrypted by the unseal key. The unseal
> key(s) is kept in a separate, external, and secure location.

#### Vault Seal Options

- Shamir Secret Sharing
  - Key shares - How many shares to split the unseal key into
  - Required threshold number (minimum) of unseal keys to unseal vault
  - Default is 5, with 3 required to unseal
  - Configured at initialization (`vault operator init`)
  - Used for sensitive operations
  - Manual user intervention required to unseal
- Auto-unseal
  - **Docs:** https://learn.hashicorp.com/collections/vault/auto-unseal
  - Provided by some external service (HSM, Azure keyvault, AWS KMS, etc)
  - Uses recovery key shares
  - To enable this seal option, set in config file or environmental variable after initialization
  - Does not require human intervention
- Seal Migration
  - Can convert either way `Shamir secret sharing <-> Auto-unseal`
  - Can be done through CLI or API

### Key Management

This is performed after Vault has been installed, configured, and initialized.

- **Rekey Unseal and Master Key**
  - Update unseal and master keys
  - Change seal settings
  - Considered a privileged operation - Will need unseal key shares
  - `vault operator rekey [OPTIONS] [KEY]`
  - Example: Change the number of key shares
    - Start the process: `vault operator rekey -init -key-shares=7 -key-threshold=5`
    - Continue process: `vault operator rekey`
    - Vault will respond with 5 unseal keys
- **Check the encryption key status**
  - Will give current version of encryption key
  - `vault operator key-status [OPTIONS]`
- **Rotate the encryption key**

  - Update encryption keyring (not master or unseal key)
  - Saves previous versions are saved
  - Must be logged in into Vault (need admin/root rights)
  - `vault operator rotate [OPTIONS]`
  - Example:

    - Login: `vault login`
    - Check status of encryption keys: `vault operator key-status`
    - Rotate encryption key: `vault operator rotate`

      - Example Output:

        - ```text
          Success! Rotated key

          Key Term            2
          Install Time        21 Jan 22 04:13 UTC
          Encryption Count    0
          ```

### Development Mode

- **Never use this in production! This is used for dev/demo/training purposed only**
- Running on Localhost
- No SSL - Using HTTP, not HTTPS
- In-memory storage only
  - Temporary
  - Once vault server stops or exits, all data is gone
  - In production, you need persistent storage / Backend
- Initial state
  - Initialized
  - Unsealed
  - Web UI enabled
  - Key/Value secrets engine enabled

**Steps to Set Up Development Mode Server**

1. Start the development vault server
   - `vault server -dev`
2. Open another terminal window
3. Export the vault server address
   - MacOS/Linux/WSL: `export VAULT_ADDR='http://127.0.0.1:8200'`
   - Windows: `$env:VAULT_ADDR="http://127.0.0.1:8200"`
4. Login in
   - `vault login <ROOT TOKEN>`
   - Use root token from output from previous `vault server -dev` output

## Interacting with Vault

1. CLI
   - General command structure: `vault <command> <subcommand> [options] [ARGUMETNS]`
   - Help menu: `vault <command> --help`
   - Getting help with given path: `vault path-help PATH`
2. Browser UI
   - UI has integrated terminal that only accepts `read`, `write`, `list`, `delete` with paths
   - It does not offer all the ability that the CLI offers
3. API
   - Typical HTTP/HTTPS RESTful response/request


## Environmental Variables

- All vault environment variables are prefixed with `VAULT_`

  - `VAULT_ADDR` - Vault server address
  - `VAULT_TOKEN` - Vault token for requests
  - `VAULT_SKIP_VERIFY` - Skip SSL verification. No verify TLS certificate.
    - Useful for self-signed certificates / Dev environment
  - `VAULT_FORMAT` - Output format. Default is "JSON"
    - JSON
    - YAML
    - TOML
  - `VAULT_UNSEAL_KEY` - Unseal key for vault

- If server address not specified, you may get something like this:
  - `Error checking seal status: Get "https://127.0.0.1:8200/v1/sys/seal-status": http: server gave HTTP response to HTTPS client`

## Vault UI

- Uses API on backend (as everything else that interacts with vault)
- Not enabled by default, must turn on in vault configuration file
    - `ui = true`
- Runs on the same port as API (Port `8200`)
- Includes a basic console within the UI for basic vault commands
- Getting to the UI
  1. Navigate web browser to `<VAULT HOST>:<PORT>/ui`
     - **Example:**
        - Local vault server: http://127.0.0.1:8200/ui
        - Remote vault server: https://vault.example.com:8200/ui
  2. Enter your token for access
- Can copy current token (top right icon)

## Vault API

- RESTful API - Request -> JSON format response
- Used by any interaction with vault, including UI and CLI in the background
- Can be used by any request tools (ie. curl, python's request module, etc)
- Request needs to add a vault token into each request with `X-Vault-Token` header
    - Can also use `--header "Authorization: Bearer <TOKEN>"`
- **Example:** GET request: Get host information
  - ```bash
    curl \
      --header "X-Vault-Token: s.LM8e4O4XYubyr9Rq9GTFkEh1" \
      --request GET \
      http://127.0.0.1:8200/v1/sys/host-info
    ```
- **Example:** POST request: Tune a secret

  - ```bash
    cat payload.json
    {
      "options": {
          "version": "2"
      }
    }

    curl \
        --header "X-Vault-Token: JSDL2073lkhLLHDF983FD" \
        --request POST \
        --data @payload.json \
        http://127.0.0.1:8200/v1/sys/mounts/secret/tune
    ```

## Authentication Methods

_The point of auth methods is to generate a vault access token, then use that token to log into and use vault._

- Provided by plug-ins with binary
- Can enable multiple auth methods
  - Can also enable multiple instances for multiple auth methods
- References **external** sources
  - LDAP, GitHub, AWS IAM, etc
- Default auth method
  - Token
  - Cannot disable it
- All auth methods are in `/auth` path

> **Note:** Exam will cover choosing the correct auth method for a given scenario



### Auth Method Categories

- **Cloud Providers:** AWS, Azure, GCP, etc
- **Cloud Native:** Kubernetes, Cloud Foundry, Github, JWT
- **Traditional:** LDAP, RADIUS, Kerberos, etc
- **Vault Native (Internal):** Token, AppRole, Userpass

### Choosing Auth Method

- Who is going to access Vault?
  - External/Internal
  - Human/Machine
- How are they going to access it?
- What do they use today?
  - GitHub Accounts
  - Active directory
  - Certificates
- See which suits the client and environment

### Auth Method: Userpass

**Docs:** https://www.vaultproject.io/docs/auth/userpass

- For human operators
- Composed of username and password only
- Enable userpass:
  - `vault auth enable userpass`
- Tune userpass:
  - `vault auth tune -description "My Userpass" userpass/`
- Create userpass user:
  - `vault write auth/userpass/users/<USERNAME> password=<PASSWORD>`
- Login using userpass
  - `vault login -method=userpass username=<USERNAME>` (Prompts for password)
  - `vault login -method=userpass username=<USERNAME> password=<PASSWORD>`

### Auth Method: AppRole

**Docs:** https://www.vaultproject.io/docs/auth/approle

- Used for machines and apps
- Consists of RoleID ("Username") and SecretID ("Password")
- Client/Service/Application already has the RoleID and SecretID
  - Vault server pushes SecretID to the client
  - Client holds RoleID and SecretID when it boots up (maybe through configuration management or image)
- **AppRole Set up**

  - Executed anywhere before using AppRole
  - Enable AppRole:
    - `vault auth enable approle`
  - Tune AppRole:
    - `vault auth tune -description "My AppRole" approle/`
  - Create a named role:
    - ```
      vault write auth/approle/role/<ROLE_NAME> \
          role_name=<ROLE_NAME> \
          secret_id_ttl=<SECRET_ID_TTL> \
          token_num_uses=<TOKEN_NUM_USES> \
          token_ttl=<TOKEN_TTL> \
          token_max_ttl=<TOKEN_MAX_TTL>
      ```

- **Getting the SecretId**

  - Can be done within the client or before deployment, adding it to the client image
  - Need `role_id`
    - `vault read auth/approle/role/<ROLE_NAME>/role-id`
  - Need `secret_id`
    - `vault write -force auth/approle/role/<ROLE_NAME>/secret-id`
    - Note the `write`, this generates data
    - Generated on the fly, or can specify the `secret_id`
    - This yields `secret_id`, `secret_id_accessor`, and `secret_id_ttl`

- **Getting the Client Vault Token**
  - Executed by the client machine to further interact with vault for further vault usage
  - This yields a token and its information
  - Passed data includes `role_id` and `secret_id`
  - Using CLI:
    - ```
      vault write auth/approle/login \
          role_id=<ROLE_ID>
          secret_id=<SECRET_ID>
      ```
  - Using REST API
    - POST to `<VAULT_ADDR>/v1/auth/approle/login`

### Auth Method: AWS

- Enable AWS:
  - `vault auth enable aws`
- Configure credentials
  - ```bash
     vault write auth/aws/config/client \
        secret_key=vCtSM8ZUEQ3mOFVlYPBQkf2sO6F/W7a5TVzrl3Oj \
        access_key=VKIAJBRHKH6EVTTNXDHA
    ```
- More: https://www.vaultproject.io/docs/auth/aws#authentication


### Configuration

- All authentication methods are enabled on vault path `/sys/auth`
- When enabled, all methods are enabled on a path
  - If not specified, the path defaults to the actual method name
- Methods cannot be moved after they are set on a path
- Once enabled, can be tuned and configured
  - **Tunning:** Common operation for all auth methods (ie. change description)
  - **Configuration:** Specific to each auth method (in `/sys/auth/<method>/config`)

### Basic Commands

- List existing auth methods
  - `vault auth list`
- List available options
  - `vault path-help auth/<AUTH METHOD NAME>`
- Enable an auth method
  - `vault auth enable [options] TYPE`
  - Enable userpass
    - `vault auth enable userpass`
    - `vault auth enable -path=globopass userpass` (With custom auth path)
  - Enable approle
    - `vault auth enable approle`
- Tune auth method:
  - `vault auth tune [options] PATH`
  - **Example:** Changing the description of an auth method
    - `vault auth tune -description="First userpass" globopass/`
- Disable:
  - **Warning:** This will remove all info stored by this auth method
  - `vault auth disable [options] PATH`

### Authenticating (Logging in)

Can be done using `vault login` or `vault write`

- **Using `vault login`**
  - **Docs:** https://www.vaultproject.io/docs/commands/login
  - For interactive methods view user
  - Will result in token and token information
  - `vault login`
    - Will prompt for token in terminal
  - `vault login [TOKEN]`
    - Will use provided token without prompting for token
    - **Example:**
      - `vault login s.2f3c5L1MHtnqbuNCbx90utmC`
  - `vault login [options] [AUTH METHOD KEY-VALUE PAIRS]`
    - Depends on the auth method used
    - **Examples:**
      - `vault login userpass username=<USERNAME> password=<PASSWORD>`
      - `vault login -method=github -path=github-prod`
  - `-token-only` - Output vault token only after authentication 
  - `-no-print` - No output (quite)
- **Using `vault write`**
  - For a particular auth method path
  - For any other method (AppRole, LDAP, etc)
  - `vault write [options] PATH [KEY-VALUE PAIRS]`
  - Depends on the auth method used
  - Examples:
    - `vault write auth/userpass/login/ismet password=<PASSWORD>`

### Disable Auth Method

- `vault auth disable [options] PATH`
  - **Example:** `vault auth disable approle/`
  - Note that we did not have to spacify path (auth/approle), since we are using `auth` cli sub-command

## Vault Policies

**Docs:** https://www.vaultproject.io/docs/concepts/policies

- As everything, policies are path based
- Grant or forbid access to certain paths and operations/capabilities (what you can do in Vault)
- All policies are `deny` by default (Empty policy)
- Policies are assigned/attached to tokens, identity, or auth method
- Defines permissions (ie. Access Control Lists (ACL))
- **There is no internal versioning of policies**
  - As of now, you have to version and/or back up policy iterations some other way
  - Potentially use `git` source control

### `root` Policy

- Can do ANYTHING in vault
- Careful who gets assigned this policy!
- Cannot be deleted or modified

### `default` Policy

This policy is automatically attached to all tokens.
The `default` policy attached to a token allows the following:

- `default` policy cannot be deleted or modified

- Look up their own properties
  - ```hcl
    path "auth/token/lookup-self" { ... }
    ```
- Renew themselves
  - ```hcl
    path "auth/token/renew-self" { ... }
    ```
- Revoke themselves
  - ```hcl
    path "auth/token/revoke-self" { ... }
    ```
- Look up its own capabilities on a path
  - ```hcl
    path "sys/capabilities-self" { ... }
    ```
- Look up its own entity by id or name (using policy template)
  - ```hcl
    path "identity/entity/id/{{identity.entity.id}}" { ... }
    ```

### Policy Syntax

**Docs:** https://www.vaultproject.io/docs/concepts/policies#policy-syntax

- Policies are defined as **H**ashiCorp **C**onfiguration **L**anguage (HCL) _(preferred)_ or JSON
- _Policy Path_ - Where and to what the policy is applied
- _Policy Capabilities_ - What actions are allowed
- Basic path expression: `path "some-path/in/vault"`
- Two wildcards are available for path expressions:
  1.  **Glob: `*`**
      - Always added at the _END_ of a path expression
      - This should match the extension of path (Note: This is not RegEx)
      - **Example:** `path "some-path/*"`
        - Evaluated as `path "some-path/something"` and `path "some-path/something/else"`
  2.  **Segment: `+`**
      - Always added _WITHIN_ a path
      - This should match any number of characters for a path segment
      - **Example:** `path "secrets/+/blah"`
        - Evaluated as `path "secrets/something/blah"` and `path "secrets/else/blah"`
- Note: Unless wildcards are specified, the expression is only for the specific path
    - `"secret/foo"` would only address `secret/foo`, and nothing under it
    - `"secret/foo/*"` would address everything under `secret/foo` but not `secret/foo` itself
- `list` capability allows viewing in UI

#### Examples

- **Example** Grant `read` access to only secret `secret/foo`
  - ```hcl
    path "secret/foo" {
    	capabilities = ["read", "list"]
    }
    ```
- Wildcard `*` addresses all downstream paths
  - **Example** Grant `read` and `list` access to all secrets
  - ```hcl
    path "secret/*" {
    	capabilities = ["read", "list"]
    }
    ```
- Note that any sub-path can be overridden by setting a policy:
  - ```hcl
    path "secret/super-secret" {
    	capabilities = ["deny"]
    }
    ```
- Policies rules can be set up to allow, disallow, or require policy parameters
  - **Example** `secret/restricted` can only contain any value for `foo`, and values `zip` or `zap` for `bar`
  - ```hcl
    path "secret/restricted" {
    	capabilities = ["create"]
    	allowed_parameters = {
    		"foo" = []              # <-- Allow any value for foo
    		"bar" = ["zip", "zap"]  # <-- Allow values `zip` or `zap` for bar
    	}
    }
    ```
- Can use "glob" (`*`) patterns / wildcard to match downstream paths
  - Note, this does not include the path before the `*`
  - **Example** `secret/foo/*` can match `secret/foo/bar` or even `secret/foo/bar/baz/blah`
  - ```hcl
    path "secret/foo/*" {               #<-- Does not apply to secret/foo
    	capabilities = ["read", "list"]
    }
    ```
- Any number of characters that are bounded within a single path segment, use `+`
  - **Example** Permit reading `secret/foo/bar/teamB`, `secret/bar/foo/teamB`, etc.
  - ```hcl
    path "secret/+/+/teamB" {
    	capabilities = ["read"]
    }
    ```

### Templated Policies (Dynamic Parameters)

**Docs:** https://www.vaultproject.io/docs/concepts/policies#templated-policies

- Dynamic way of defining paths in policies
- These are used within the policy files
- Using `{{ }}` to let vault interpreter know that you are adding a parameter, then adding the path to the parameter
  - **Example:** Insert the name of the entity to define a policy
    - ```hcl
      path "secret/{{identity.entity.name}}/*" { ... }
      ```
  - **Example:** Use the id of the entity to define a policy
    - ```hcl
      path "secret/{{identity.entity.id}}/*" { ... }
      ```
- **NOTE:** Currently, the only source for parameters is the `identity` secrets engine
  - **`identity.entity`** - `id`, `name`, `metadata`, `aliases`
  - **`identity.groups`** - `ids`, `names`

### Policy Capabilities

**Docs:** https://www.vaultproject.io/docs/concepts/policies#capabilities

- Follows CRUD semantics (**C**reate, **R**ead, **U**pdate, **D**elete)

  - `create` - Creating data at the given path (similar to `update`) _(REST `POST/PUT` request)_
  - `read` - Reading data at the given path _(REST `GET` request)_
  - `update` - Changing data at given path _(REST `POST/PUT` request)_
  - `delete` - Deleting data at given path _(REST `DELETE` request)_

- Additional capabilities:
  - `list`
    - Listing data at given path
    - No access to key data (REST `LIST` request)
    - Allows viewing in the Vault web UI
  - `sudo` - Give token holder cccess to paths that are _root-protected_
  - `deny` - Disallow access to given path or path pattern. Overrides any other allow action

### Policy Evaluation Rules

- Policies which Vault applies to tokens are determined by the most-specific match available
  - **Example:** `secret/foo/bar` is more specific than `secret/*`
- If same policy path pattern appears in multiple policies, the union of both is taken
  - **Example:** Combine `[read, list]` with `[create]` is `[read, list, create]`
- If different patterns appear in multiple policies, the highest-precedence one is taken

### Working with Policies

- List existing policies
  - `vault policy list`
  - `vault read /sys/policy`
- Read the contents of a policy
  - `vault policy read [OPTIONS] [POLICY NAME]`
    - **Example:** `vault policy read secrets-mgmt`
  - `vault read sys/policy/[POLICY NAME]`
- *Write* a new policy or *update* an existing policy
  - Using a File: `vault policy write [OPTIONS] [POLICY NAME] [POLICY FILE]`
    - **Example:** `vault policy write secrets-mgmt policy.hcl`
  - Using Standard In: `vault policy write [OPTIONS] [POLICY NAME] -`
    - **Example:** `cat policy.hcl | vault policy write secrets-mgmt -`
- Delete a policy
  - `vault policy delete [OPTIONS] [POLICY NAME]`
    - **Example:** `vault policy delete secrets-mgmt`
- Format the policy (make more readable syntax)
  - `vault policy fmt [OPTIONS] [POLICY FILE]`
    - **Example:** `vault policy fmt policy.hcl`

### Assigning Policies

Here the policy has to already be created and active in Vault to be assigned.

1. Associate policy directly with a token at token creation
   - **Example:** `vault token create -policy=secrets-mgmt`
2. Assign policy to a user in userpass
   - **Example:** `vault write auth/userpass/users/ismet token_policies="secrets-mgmt"`
3. Assign policy to an entity in the identity secrets engine
   - **Example:** `vault write identity/entity/name/ismet policies="secrets-mgmt"`

### Parameter Constraints

**Docs:** https://www.vaultproject.io/docs/concepts/policies#fine-grained-control

1. `required_parameters` - List of parameters that must be set
   - **Example**: Requires users to create sub-items within `secret/foo` with `bar` and `baz`
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	required_parameters = ["bar", "baz"]
       }
       ```
2. `allowed_parameters` - Keys and values that are permitted on the given path

   - **Example**: Allows users to create `secret/foo` with ONLY `bar`, with `bar` containing ANY value
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	allowed_parameters = {
       		"bar" = []
       	}
       }
       ```
   - **Example**: Allows users to create `secret/foo` with ONLY `bar`, with `bar` containing ONLY `zip` and `zap`
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	allowed_parameters = {
       		"bar" = ["zip", "zap"]
       	}
       }
       ```
   - **Example**: Allows users to create `secret/foo` with any key and value, but if user creates `bar`, it must be `zip` or `zap`
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
   - **Example**: Allows users to create `secret/foo` with any parameter but not named `bar`
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	denied_parameters = {
       		"bar" = []
       	}
       }
       ```
   - **Example**: Allows users to create `secret/foo` with parameter named `bar`, which cannot contain `zip` or `zap`
     - ```hcl
       path "secret/foo" {
       	capabilities = ["create"]
       	denied_parameters = {
       		"bar" = ["zip", "zap"]
       	}
       }
       ```


## Tokens

**Docs:**: https://www.vaultproject.io/docs/concepts/tokens

- Used for authentication within Vault
- Tokens are a collection of data used to access Vault
- Used directly or via auth methods (dynamically generated)
- Tokens are mapped to policies for authorization and metadata for auditing purposes

### Creating Tokens

Tokens can be created in the following ways:

1. **Auth method** - Tokens are generated by an auth method (userpass, github, aws, etc)
2. **Parent token** - Using existing token to generate a child token
3. **Root token** - Requires a special process to generate
   - Can do ANYTHING (Dangerous)
   - Does not expire
   - Created via the following:
     1. Initialize Vault server
     2. Existing root token
     3. Using `operator` command
   - _Revoke it as soon as possible / As soon as action is completed_
     - Create it as needed
   - Why create a root token?
     1. Perform initial vault setup
     2. If main auth method is not available
     3. Emergency situation where root token is needed

### Token Properties

This list is not exhaustive.

- `id` - Unique token ID
- `accessor` - A value to use lookup the token, without needing to use it
- `type` - What type of token it is, "service" or "batch"
- `policies` - List of policies that the token is allowed to access
- `ttl` - Time to live of the token. How long will it be valid for.
- `orphaned` - Whether the token has a parent token or is a stand-alone
- Example token properties
  - ```text
    $ vault token lookup s.5kpKplh3BS1lWjGU2kY6zJAM

    Key                 Value
    ---                 -----
    accessor            AGR6cgoicILcBGE1PgiwqNhd
    creation_time       1643577866
    creation_ttl        768h
    display_name        token
    entity_id           n/a
    expire_time         2022-03-03T16:24:26.3057503-05:00
    explicit_max_ttl    0s
    id                  s.5kpKplh3BS1lWjGU2kY6zJAM
    issue_time          2022-01-30T16:24:26.3057549-05:00
    meta                <nil>
    num_uses            5                                    <-- Allowed to be used 5 times
    orphan              false
    path                auth/token/create
    policies            [default]
    renewable           true
    ttl                 767h59m49s                           <-- Time until expiration if not renewed
    type                service
    ```


### Token Accessor

**Docs:** https://www.vaultproject.io/docs/concepts/tokens#token-accessors

- Only able to view token properties (metadata), cannot retrieve the actual ID of the token
- View capabilities on a given path
- Used for token management such as renew or revoke a token
  - More token management: https://www.idkrtm.com/hashicorp-vault-managing-tokens/
- Some situation you may need it:
  - Some program may only need ability to revoke a token and check status of child tokens
  - View list of all tokens issued, like: `vault list auth/token/accessors`
  - Audit token usage by accessor in audit log. ID won't be seen
- Example of accessor token info:
  - ```text
    $ vault token lookup -accessor AGR6cgoicILcBGE1PgiwqNhd

    Key                 Value
    ---                 -----
    accessor            AGR6cgoicILcBGE1PgiwqNhd
    creation_time       1643577866
    creation_ttl        768h
    display_name        token
    entity_id           n/a
    expire_time         2022-03-03T16:24:26.3057503-05:00
    explicit_max_ttl    0s                                 <-- No set Max TTL
    id                  n/a                                <-- Not available with accessor
    issue_time          2022-01-30T16:24:26.3057549-05:00
    meta                <nil>
    num_uses            5
    orphan              false
    path                auth/token/create
    policies            [default]
    renewable           true
    ttl                 767h58m18s
    type                service`
    ```


### Working with Tokens

- Create a new token
  - `vault token create [OPTIONS]`
    - **Example:** `vault token create -policy=my-policy -ttl=60m`
    - **Example:** `vault write auth/token/create -policy=default -ttl=60m`
- View token properties
  - `vault token lookup [OPTIONS] [ACCESSOR or ID]`
    - **Example:** `vault token lookup -accessor=FJKD0870sdfjlhjsdf07sdfY`
  - Can also view your own token
    - `vault token lookup`
- Check capabilities/permissions for a specific path
  - `vault token capabilities [TOKEN] [PATH]`
    - **Example:** `vault token capabilities x.TG08098SLDLFHlsdhflsdhSDFI secret/foo`
- Renew a token
  - `vault token renew [OPTIONS] [ACCESSOR or ID]`
    - **Example:** `vault token renew -increment=30m -accessor=FJKD0870sdfjlhjsdf07sdfY`
- Revoke a token
  - `vault token revoke [OPTIONS] [ACCESSOR or ID]`
    - **Example:** `vault token revoke -accessor=FJKD0870sdfjlhjsdf07sdfY`
- List all accessors tokens
  - `vault list /auth/token/accessors`

> **Note:** Can also use API format: `vault write auth/token/....`

### Token Types

1. **Service Token**

   - Default type of token for most situations
   - Fully featured
   - Heavyweight
   - Has to written to storage backend
   - Can be managed via token accessor or token ID
   - Root and periodic tokens are service tokens
   - Calculated lifetime based on token TTL or any renewals for that token
   - Can create child tokens
   - Begins with **"s."** in token ID
   - **Example:**
     - `vault token create -policy=my-policy -ttl=60m`

2. **Batch Token**

   - Not default, must be explicitly created
   - Limited features
   - Lightweight
   - Not written to persistent storage backend
   - Has no token accessor (metadata)
   - Static lifetime - Once created and TTL set, cannot be renewed
   - Has no child tokens
   - Begins with **"b."** in token ID
   - **Example:**
     - `vault token create -type=batch -policy=default -ttl=30m`

3. Token Type: **Periodic**
   - Is also a service token
   - Not default, must be explicitly created
   - Can be renewed indefinitely, does not expire, no max TTL
   - TTL is set to period at creation and renewals
   - Requires root (`sudo`) privileges to create
   - Renewals cannot exceed what has been provided by `-period`
   - **Example:**
     - Create: `vault token create -policy=default -period=2h`
     - Renew: `vault token renew -increment=60m s.YvR0cqzXsDDdCne0w28QZ4kr`

### Token Lifetime

- TTL (Time to Live) - How long the token is valid for
- Max TTL
  - How long can the token be valid before it cannot be renewed anymore
  - Cannot renew the token past this point
  - `token-max-ttl`

#### Working with Token Lifetime

- Renew a token
  - `vault token renew [OPTIONS] [ACCESSOR or ID] [ -increment=<DURATION> ]`
    - **Example:** Extend the currently active token by 30 minutes
      - `vault token renew -increment=30m`
    - **Example:** Extend another token by 30 minutes
      - `vault token renew -increment=30m -accessor=FJKD0870sdfjlhjsdf07sdfY`
- Revoke a token
  - `vault token revoke [OPTIONS] [ACCESSOR or ID]`
    - **Example:** Revoke the currently active token
      - `vault token revoke -self`
    - **Example:** Revoke another token
      - `vault token revoke -accessor=FJKD0870sdfjlhjsdf07sdfY`

#### Setting Maximum Token TTL

> **Note:** Default max TTL is 32 days (768 hours)

The TTL is evaluated form the very top (general) TTL to token-level.

1. System max TTL

   - System-wide setting for maximum TTL
   - Defined within Vault configuration file
   - Dynamically evaluated (will check against it constantly)
   - Configuration settings: `default_lease_ttl`, `max_lease_ttl`
   - **Example:**
     - `vault server -config /etc/vault/my-config.hcl`

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
   - **Example:**
     - `vault write auth/userpass/users/ismet max-lease-ttl=72h`
     - `vault write auth/userpass/users/bob token-max-ttl=72h password=sEcReT`

## Secrets Engines

**Docs:** https://www.vaultproject.io/docs/secrets

- Plugins used by Vault to handle sensitive data
- Store, generate, or encrypt data
- Broad categories: **Dynamic** and **Static** secret engines
- General Secrets engine categories:
  - **Cloud** - AWS, Azure, GCP, etc.
  - **Database** - MSSQL, PostgreSQL, MySQL, etc.
  - **Internal** - Key/Value, Identity, Transit, etc.
  - **Identity** - Active Directory, LDAP, etc.
  - **Certificate** - SSH, PKI, etc.
  - **Tokens** - Consul, Nomad
- All engines are enabled on `/sys/mounts` path
- When enabling, if no path is provided, it will default to the engine name
  - **Example:** `vault secrets enable aws` is enabled and mounted on `/sys/mounts/aws`
- Secrets engines can be moved
  - **WARNING:** If moved, any existing leases will be revoked
  - May impact policies (which are based on specified paths)
- Engines can be tuned and configured
  - Tuning settings are same for all secrets engines (ie. description, max lease TTL, etc.)
  - Configuration settings are specific to the entire secrets engine

> **Note:** Specific secret engine are not needed for the certification exam, only
> how to generally use them.

### Types of Secrets

- **Static secrets**

  - Store existing data securely
  - You already have this data, and Vault needs to manage it, have access to it
  - Manual lifecycle management
  - Manually load new versions of secret to a secret engine
  - **Example:**
    - Key/Value (`kv`) secret engine can store some static value under some key

- **Dynamic Secrets**
  - Generated secrets data on demand
  - _Lease_ issued for each secret (TTL) that can expire
  - Automatic secrets lifecycle management
  - Majority of secrets engines are dynamic in nature

### Working with Secrets Engines

- List existing secret engines
  - `vault secrets list`
  - `-detailed` for more information for each engine
- Enable a new secrets engine
  - `vault secrets enable [OPTIONS] TYPE`
  - **Example:** Key-value version 2 secrets engine
    - `vault secrets enable -version=2 kv`
  - **Example:** Database secrets engine
    - `vault secrets enable -path=CompanyData database`
- Tune a secrets engine settings
  - `vault secrets tune [OPTIONS] PATH`
  - **Example:**
    - `vault secrets tune -max-lease-ttl=72h kv`
    - `vault secrets tune -description="Our cool database engine" CompanyData`
- Move a secrets engine
  - Will revoke all included leases
  - Could mess up policy constraints
  - `vault secrets move [OPTIONS] SOURCE DESTINATION`
  - **Example:**
    - `vault secrets move CompanyData CompanyDataPrivate`
- Disable a secrets engine
  - `vault secrets disable [OPTIONS] PATH`
  - **Example:**
    - `vault secrets disable CompanyData`
- Show secret engine help
  - `vault path-help /sys/mounts/<engine>`
  - **Example:**
    - `vault path-help /sys/mounts/CompanyData`

### Response Wrapping

**Docs:** https://www.vaultproject.io/docs/concepts/response-wrapping
**Tutorial:** https://learn.hashicorp.com/tutorials/vault/cubbyhole-response-wrapping

- Provides mechanism for information sharing between many environments
- Vault takes response it would have sent to a client and inserts it into the `cubbyhole` with
  a single-use token, returning that single-use token to the client instead
- Response it wrapped by that `cubbyhole` token
- Retrieving the actual data inside the `cubbyhole` requires an unwrap operation
  - **CLI:** `vault unwrap <wrapping token>`
  - **UI:** Tools > Unwrap > Enter token > Unwrap data
- Response wrapping provides:
  - Value transmitted is not the actual secret but a reference to the actual secret (response-wrapping token)
  - Only a single party can unwrap the token and see what's inside
  - Limits the lifetime of secret exposure. If client fails unwrap token, token can expire quickly
- Wrapped token creation
  - Use `-wrap-ttl=[DURATION]` option flag via CLI
  - Use `X-Vault-Wrap-TTL` header via API
- When a response wrap is requested ...
  - **Single-use** token is generated
  - Original response is stored in a single-use token's cubbyhole
  - New response is returned with a single-use token

> **NOTE:** The client does not have to authenticate to vault when trying to unwrap, gets instant
> access to the secret for one time only

**Using CLI**

- Wrap a response of any command
  - `vault command -wrap-ttl=[DURATION] PATH`
  - The resulting token (`wrapping_token`) is passed to entity that needs to retrieve that wrapped response
    **Example:** Create a secret, and wrap the output of the value for the specified key
    - `vault kv put kv/some_data some_key=some_value`
    - `vault kv get -wrap-ttl=1h kv/some_data`
    - Output:
      - ```text
        Key                              Value
        ---                              -----
        wrapping_token:                  s.WWSuR0GwvjJgscyqS8rffAKL
        wrapping_accessor:               XwhdoFsKzG2EEoyPQaYTZtj9
        wrapping_token_ttl:              1h
        wrapping_token_creation_time:    2022-01-21 22:28:21.2741588 +0000 UTC
        wrapping_token_creation_path:    kv/data/some_data
        ```
- Unwrap using the issued wrap token
    - `vault unwrap [OPTIONS] [TOKEN]`
    - **Example:** Unwrap the previously wrapped response
       - `vault unwrap -field=data -format=json s.WWSuR0GwvjJgscyqS8rffAKL`
       - Output:
           - ```json
             { "some_key": "some_value" }
              ```

**Using API**

Similar to CLI, but using the API in the following format:

- Wrap a response of any command. Will result in a `wrapping_token`
  - ```bash
    curl --header "X-Vault-Wrap-TTL: <TTL>" \      # <-- NOTE
        --header "X-Vault-Token: <TOKEN>" \
        --request <HTTP_VERB> \
        --data '<PARAMETERS>' \
        <VAULT_ADDRESS>/v1/<ENDPOINT>
    ```
- Unwrap using the issued token
  - ```bash
    curl --header "X-Vault-Token: <WRAPPING TOKEN>" \
        --request POST \
        <VAULT_ADDRESS>/v1/sys/wrapping/unwrap
    ```

### Secrets Engine: Cubbyhole

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

### Secrets Engine: Identity

**Docs:** https://www.vaultproject.io/docs/secrets/identity
**Tutorial:** https://learn.hashicorp.com/tutorials/vault/identity

- Maintains and keeps track of clients who are recognized by Vault
- "Clients" are users or applications that have been authenticated by Vault
- Identity engine tracks those clients internally within Vault
- Enabled/Mounted by default
- Cannot be disabled, moved, or duplicated
- Cannot enable multiple instances/paths of the identity engines
- Each client is a `Entity`
  - Entry within the identity engine that represents a client
- Any entity can have multiple `Aliases` (ways of authenticating)
  - For example, a single user who has accounts in both GitHub and LDAP,
    can be mapped to a single entity in Vault that has 2 aliases, one
    of type GitHub and one of type LDAP.
- Can place entities in different groups to manage policy assignments to entities
- Internally maintains the clients who are recognized by Vault
- Links identities to tokens
- Hold entities, aliases, and groups
- Can associate Vault policies to entities or groups
  - Typical token policies are assigned and evaluated at creation and renewal time **(static)**
  - Identity policies are assigned to entity or group, evaluated at each request **(dynamic)**:
- Three main components
  1. **Entity**
      - Represents a client (user, machine, etc)
      - Linked to a token
      - Example: Create an entity
        - `vault write identity/entity name=my_entity`
  2. **Alias**
      - Represents a way of authentication method objects (ie. aws, github, ldap, etc)
      - Linked to an entity (or group)
  3. **Group**
      - Internally organized groups
        - Vault internally created group
        - Can contain other groups and entities
      - Externally organized groups
        - Auth methods such as LDAP, Okta, or GitHub
        - Use aliases for membership
      - Can have entities or other groups as members
      - Can create a hierarchy of groups, with policy inheritance

### Secret Engine: Database

**Docs:** https://www.vaultproject.io/docs/secrets/databases

- Credentials dynamically generated with the database itself
- Credentials are short-lived
- Applications/Services request credentials from vault, which in turn generates it through database
- Also supports static roles, a 1-to-1 mapping between vault roles to username/password

### Secret Engine: Key Value (KV)

**Docs:** https://www.vaultproject.io/docs/secrets/kv

There are two version of this engine

- **Key Value Version 1**

  - No versioning, last key wins
  - Faster with fewer storage calls
  - Deleted items are gone forever
  - Can be upgraded to version 2
  - Default version on creation

- **Key Value Version 2**

  - Versioning of past secrets
  - Possibly less performant
  - Deleted items and metadata retained, can be recovered
  - Cannot be downgraded to version 1
  - Can be specified at creation

- Usage

  - **Docs:**: https://www.vaultproject.io/docs/secrets/kv/kv-v2#usage
  - Getting help: `vault kv --help`
  - Create/Writing a secret:
    - `vault kv put [OPTIONS] KEY [DATA KEY=VALUE]`
    - **Example:** `vault kv put kv/apikeys/d101 token=1234567890`
    - **Example:** `vault kv put kv/apikeys/d101 @some_file.txt`
  - Read a secret:
    - `vault kv get [OPTIONS] KEY`
    - **Example:** `vault kv get -version=2 kv/apikeys/d101`
    - **Example:** `vault kv get -field=token kv/apikeys/d101`
    - **Example:** `vault kv get -format=json kv/apikeys/d101`
  - Listing secrets:
    - `vault kv list [OPTIONS] PATH`
    - **Example:** `vault kv list kv/apikeys`
  - Deleting a secret:
    - `vault kv delete [OPTIONS] KEY`
    - **Example:** `vault kv delete -versions=1 kv/apikeys/d101`
  - Permanently destroy a secret:
    - `vault kv destroy [OPTIONS] KEY`
    - **Example:** `vault kv destroy kv/apikeys/d101`

- Example using REST API:
  - Note the `data` in the path
    - ```bash
      curl --header "X-Vault-Token: [VAULT TOKEN]" \
            http://127.0.0.1:8200/v1/kv/data/apitokens/d102
      ```
  - Getting a specific version of the key value
    - ```bash
      curl --header "X-Vault-Token: [VAULT TOKEN]" \
            http://127.0.0.1:8200/v1/kv/data/apitokens/d102?version=1
      ```

### Secret Engine: Transit

**Docs:** https://www.vaultproject.io/docs/secrets/transit
**Tutorial:** https://learn.hashicorp.com/tutorials/vault/eaas-transit

- Provides **encryption as a service**
- Doesn't store the data sent to this engine
- Only the encrypted keys are stored
- Supported actions:
  - Encrypt and decrypt data
  - Can sign and verify that data
  - Generate hashes
  - Create random bytes
- Relieves burden of proper encryption/decryption
- Encryption keys that it uses to perform all actions are maintained the Transit secrets engine
- Default path is `transit/`
- Operations
  - Enable engine
  - Add cryptographic keys
  - View keys and versions
  - Encrypt data with key
  - Decrypt data with key
  - Rotate and manage key versions
- Cryptographic keys features
  - Basic types: AES, ChaCha20, ED25519, ECDSA, RSA, etc.
  - The key type determines the supported actions
  - Convergent encryption
    - Deterministic - Regardless of key version, the encryption value will always be the same
    - Less secure - Bad actor can infer values, since it always resolves to the same output
    - Kind of like a hash
    - Not supported by all key types
  - Key versioning
    - Each key is a map of key versions
    - Working set - All available versions of the key that vault can reference (in memory)
    - Retired set - Keys stored in archive (not in memory)
    - Versioning settings
      - `min_decryption_version` - Minimum key version to decrypt data
      - `min_encryption_version` - Minimum key version to encrypt data
    - `rotate` - Add a new version
    - `config` - Change version settings
    - `trim` - Delete key permanently

#### Working with Transit Engine

- Enable the transit engine
  - `vault secrets enable transit`
- Create a new encryption key
  - `vault write [-force] PATH/<KEY_NAME> [DATA] [PARAMETERS]`
  - **Example:** Let Vault generate key `my_key` without given input
    - `vault write -force transit/keys/my_key`
- List encryption keys
  - `vault list PATH`
  - **Example:** List all keys 
    - `vault list transit/keys`
- Read key info
  - `vault read PATH/<KEYNAME>`
  - **Example:** Read key info
    - `vault read transit/keys/my_key`
- Rotate a key
  - `vault write [-force] PATH/rotate [DATA]`
  - **Example:** Rotate a key
    - `vault write -force transit/keys/my_key/rotate`
- Configure available key versions
  - `vault write PATH/config/ [PARAMETERS]`
  - **Example:** Change minimum decryption version available for use
    - `vault write transit/keys/my_key/config min_decryption_version=4`
- Remove older key versions
  - `vault write PATH/trim [PARAMETERS]`
  - **Example:** Remove all key versions before version 3 (delete versions 1, 2)
    - `vault write transit/keys/my_key/trim min_available_version=3`
- Generate a random number
  - `vault write -force transit/random/[BYTES] format=[FORMAT]`
  - Number of bytes could be `32`, `128`, etc
  - `-format` can be `base64` or `hex`
  - **Example:** Generate a random number of 32 bytes in base64 format
    - `vault write -force transit/random/32 format=base64`
- Encrypt plain text data with encryption key
  - `vault write transit/encrypt/<KEY_NAME> plaintext=$(base64 <<< "TEXT")`
  - **Note:** All submitted plaintext data must be base64 encoded
  - If key version is not specified, the latest version will be used
  - **Example:** Encrypt some text
    - `vault write transit/encrypt/my-key plaintext=$(base64 <<< "my secret data")`
    - Output:
      - ```text
        Key            Value
        ---            -----
        ciphertext     vault:v2:nKSQ9Ykv+CPCWfMSHA6tjgFOI2nunYMp00et0heBhtJH0wdnr90hO61fbw==
        key_version    2
        ```
  - **Example:** Encrypt data and save the ciphertext in a variable
    - Note the usage of JSON format and `jq` parser
    - `json_data=$(vault write transit/encrypt/ccid plaintext=$(base64 <<< "my secret data") -format=json)`
    - `ciphertext=$(echo $json_data | jq .data.ciphertext -r)`
- Decrypt data
    - `vault write transit/decrypt/<KEY_NAME> ciphertext="CIPHERTEXT"`
    - Will return the decrypted plaintext in base64 encoding
    - **Example:** Decrypt some ciphertext using the `ccid` key
      - `vault write transit/decrypt/ccid ciphertext="vault:v2:nKSQ9Ykv+CPCWfMSHA6tjgFOI2nunYMp00et0heBhtJH0wdnr90hO61fbw=="`
        - Output:
          - ```text
            Key          Value
            ---          -----
            plaintext    bXkgc2VjcmV0IGRhdGEK
            ```
      - `base64 --decode "bXkgc2VjcmV0IGRhdGEK"`
        - Output:
          - ```text
            my secret data
            ```
    - **Example:** Decrypt data and get the plaintext
      - `plaintext=$(vault write transit/decrypt/ccid ciphertext=$ciphertext -format=json | jq .data.plaintext -r)`
      - `echo $plaintext | base64 --decode`


## Leases

- Control dynamic secret lifecycle
- Dynamic secrets and service tokens are created with a lease
  - "Leases" are for dynamic secrets
  - "TTL" are for service tokens
- Can renew or revoke a lease
- Leases have no direct CLI command
  - Use `/sys/leases/lookup` path
- Lease Properties
  - `lease-id` - Unique identifier for the dynamic secret
  - `lease_duration` - How much longer is this lease valid for
  - `lease_renewable` - Is this lease renewable (true or false)
- `lease_duration` is essentially the TTL
  - Has default TTL
  - Maximum TTL
  - TTL inheritance
    - System-wide vault server config
    - Mount-specific config (changed with `tune`)
    - Object-specific config for each dynamic secret
- `lease_renewable` is whether or not the lease can be renewed
  - Set at object level

### Working with Leases

- Renewing a lease
  - `vault lease renew [OPTIONS] LEASE_ID`
  - **Example:** `vault lease renew -increment=30m consul/creds/web/KWq5lsjdsf89sfjsdfG`
  - Must be less than the max TTL
- Revoking a lease
  - `vault lease revoke [OPTIONS] LEASE_ID`
  - **Example:** `vault lease revoke consul/creds/web/KWq5lsjdsf89sfjsdfG`
- Prefix Revocation
  - Revokes all leases with a given common parent path
  - Requires elevated `sudo`/root privileges
  - `vault lease revoke -prefix consul/creds/web/`
- Lookup active leases
  - `vault list [OPTIONS] sys/leases/lookup/PATH`
  - **Example:** `vault list sys/leases/lookup/consul/creds/web/`
- View leases properties
  - `vault write [OPTIONS] sys/leases/lookup/ lease_id=LEASE_ID`
  - **Example:** `vault write sys/leases/lookup/ lease_id=consul/creds/web/KWq5lsjdsf89sfjsdfG`
  - Note, this is a write/POST operation since we are submitting data in part of the request


## Vault Agent

**Docs:** https://www.vaultproject.io/docs/agent


- Vault agent is a client deamon or service
- Part of the vault binary
- Configured using HashiCorp Configuraiton Language (HCL)
- Integration Challenges solved by vault agent
  - Handling authentication
  - Managing tokens and leases
  - Secret storage and renewal
- Starting a vault agent:
  - `vault agent -config=/path/to/config.hcl`


### Auto-Auth

**Docs:** https://www.vaultproject.io/docs/agent/autoauth

- Vault agent's ability to automatically authicate client and manage token
- Renewal of token when possible
- **Method**
  - Auth method used to authenticate with server (ie. userpass, approle, etc)
- **Sink**
  - Local location where agent should wriet token
  - Just a local file
  - Application/Service will consume this value and talk to vault server
- Token in the sink file can be response-wrapped or encypted
- Application gets token from sink -> vault auth request to agent -> agent proxies auth request to server
- Auto-auth configuraiton inside vault agent configuraiton file
  - Auth method can be approle, aws, kubernetes, etc
  - ```hcl
    auto_auth {
      method = "name" {
        mount_path = "path/to/auth_method"
        config = {...}                 # <-- Settings for specific auth method
      }
      sink = "file" {                  # <-- Only sink type supported so far
        config = {
          path = "/path/to/file"       # <-- Path for tokenm file
        } 
      }
   
    ```

### Caching

**Docs:** https://www.vaultproject.io/docs/agent/caching

- Secrets and token caching locally
- All requests must use vault agent, cannot go straight to server
- Imporves performance (reads local cache)
- Works with auth-auth to skip authenticaiton to server
- Renews secrets and tokens when possible
- Caching configuraiton inside the agent configuraiton file
  - ```hcl
    cache {
      use_auto_auth_token = true   # <-- Forcing vault agent to use auto-auth token
    }
    listener "tcp" {               # <-- Can also be unix socket ("unix")
      address = "127.0.0.1:8100"   # <-- Vault agent listens on this address. Can be URL if TCP or file for unix socket
      tls_disable = true           # <-- In production, probably want this to false
    }
    ```

### Templates

**Docs:** https://www.vaultproject.io/docs/agent/template

- Uses Consul template markup language (Won't be on exam)
- Render secrets to files
- Takes secrets response from vault server and renders them to a files
- Can set persmisisons on files
- Can run arbitrary commands
  - Create environment variable referenced later
  - Update the applicaton with secrets information
- Tempalte configuration inside the agent configuraiton file
  - ```hcl
    template {
      source = "template.ctmpl"     # <-- Template file writen in Consul language
      destination = "/path/to/file" # <-- Path to file to write rendered template
      perm = "640"                  # <-- File permissions of destination file
    }
    ```
- Consul templating: Simple Vault secret read
  - **Docs:** https://github.com/hashicorp/consul-template/blob/master/docs/templating-language.md#secret
  - Example of a template file
    - ```consul
      {{ with secret "secret/my-secret" }}  #<-- "secret" function and path to secret in vault
      {{ .Data.data.foo }}                  #<-- Reads "foo" key from secret
      {{ end }} 
      ```
    - The value of vault secret `my-secret`, field `foo` will be written to the sink file


## System Backend

**Docs:** https://www.vaultproject.io/api/system

- System Backend is mounted at `/sys`
- Cannot be disabled or moved
- Remember to use when using the CLI with `read`, `write`, `list`, `delete`
  - **Examples:**
    - `vault read sys/policy/default -format=json`
    - `vault read /sys/auth`
    - `vault list transit/keys`
- Remember to use when using the API with `GET`, `POST`, `LIST`, `DELETE`
  - **Examples:**
    - ```hcl
      curl \
          --header "X-Vault-Token: ..." \
          --request PUT \
          --data @payload.json \
          http://127.0.0.1:8200/v1/sys/leases/renew
      ```
- Endpoints:
  - `/sys/auth` - Manage authenticaiton methods
  - `/sys/policy` - Manage policies
  - `/sys/leases` - Manage leases
  - `/sys/mounts` - Used to manage secrets engines in Vault
  - ... more
