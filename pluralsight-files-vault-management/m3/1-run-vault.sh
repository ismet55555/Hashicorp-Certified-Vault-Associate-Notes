# We are going to use Docker Desktop to spin up our instance of Vault server
# Set the full path of the director for server1

# Assuming we're in m3 at the moment
parentPath=$(dirname $(pwd))
certPath=${parentPath}/certs
mkdir $certPath

vaultPath=${parentPath}/server1
mkdir ${vaultPath}/certs
mkdir ${vaultPath}/data

# Let's create some certificates!

#Let's create a local Certificate Authority using openssl
SUBJECT="/C=US/ST=Pennsylvania/L=Springfield/O=Globomantics/OU=IT/CN=Contoso"

#Create a CA key
openssl genrsa -out $certPath/ca.key.pem 4096

#Creata a CA certificate
openssl req -key $certPath/ca.key.pem -new -x509 -days 7300 -sha256 -out $certPath/ca.cert.pem -extensions v3_ca -subj $SUBJECT

# Create server certificate
# server cert
cat > "$certPath/server1.conf" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
subjectAltName = @alt_names
[alt_names]
DNS = server1
EOF

openssl genrsa -out $certPath/server1.key 4096

#Create the certificate from the request
openssl req -new -key $certPath/server1.key -out $certPath/server1.csr -subj "/CN=server1/O=server1" -config "$certPath/server1.conf"

openssl x509 -req -days 180 -CA $certPath/ca.cert.pem -CAkey $certPath/ca.key.pem -CAcreateserial -in $certPath/server1.csr -out $certPath/server1.pem

# Copy certs to server1 directory
server1Path=$parentPath/server1/certs
cp $certPath/server1.key $server1Path/vault_key.key
cp $certPath/server1.pem $server1Path/vault_cert.pem
cat $certPath/ca.cert.pem >> $server1Path/vault_cert.pem


docker run --name server1 --hostname server1 -d -v ${parentPath}/server1:/vault -p 8200:8200 vault:1.6.3 server

# Now we'll set our environment variables
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true