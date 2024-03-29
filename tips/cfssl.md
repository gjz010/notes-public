# cfssl Tips

Most usages are taken from official repository: https://github.com/cloudflare/cfssl

```nix
nix shell nixpkgs#cfssl
```

## Initialization

Create a directory to store all certificates.

```bash
mkdir -p my-certs
cd my-certs
CERTROOT=$PWD
```

Then create the following `cfssl.json` [file](https://rob-blackbourn.medium.com/how-to-use-cfssl-to-create-self-signed-certificates-d55f76ba5781) into `$CERTROOT`:

```json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "intermediate_ca": {
        "usages": [
            "signing",
            "digital signature",
            "key encipherment",
            "cert sign",
            "crl sign",
            "server auth",
            "client auth"
        ],
        "expiry": "8760h",
        "ca_constraint": {
            "is_ca": true,
            "max_path_len": 0, 
            "max_path_len_zero": true
        }
      },
      "peer": {
        "usages": [
            "signing",
            "digital signature",
            "key encipherment", 
            "client auth",
            "server auth"
        ],
        "expiry": "8760h"
      },
      "server": {
        "usages": [
          "signing",
          "digital signature",
          "key encipherment",
          "server auth"
        ],
        "expiry": "8760h"
      },
      "client": {
        "usages": [
          "signing",
          "digital signature",
          "key encipherment",
          "client auth"
        ],
        "expiry": "8760h"
      }
    }
  }
}
```

> [!warning]
> Before every step below, you need to switch to the root directory (`$CERTROOT`) first!

## Create CA certificate

```bash
mkdir -p ca/ && cd ca/
cat <<EOF > csr-ca.json
{
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "CN": "My own Root CA"
}
EOF
# This generates ca.csr, ca.pem and ca-key.pem
cfssl gencert -initca csr-ca.json | cfssljson -bare ca -
# Verify the certificate
openssl verify -CAfile ca.pem ca.pem
```

## (Optional) Create Intermediate CA

```bash
mkdir -p intermediate && cd intermediate/
cat <<EOF > csr-intermediate.json
{
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "CN": "My own Intermediate CA"
}
EOF
# This generates intermediate.csr, intermediate.pem and intermediate-key.pcm
cfssl gencert -config ../cfssl.json -profile=intermediate_ca -ca ../ca/ca.pem -ca-key ../ca/ca-key.pem csr-intermediate.json | cfssljson -bare intermediate -
# Verify the certificate
openssl verify -CAfile ../ca/ca.pem intermediate.pem
```

If you have created an Intermediate CA, you may want to:
- Pull `ca-key.pem` offline for more security.
- Sign all server and client certificates with Intermediate CA instead of CA.
- Bundle `intermediate.pem` when creating PKCS\#12 certs.

## Create server or client certificate

```bash
CERTNAME=my-openvpn-server
CATYPE=ca # Use "intermediate" if you created an Intermediate CA.
CERTPROFILE=server # Use "client" if you want to create a client certificate.
mkdir -p $CERTNAME && cd $CERTNAME/
cat <<EOF | sed "s/@CERTNAME@/$CERTNAME/g" > csr-$CERTNAME.json
{
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "CN": "@CERTNAME@"
}
EOF
# This generates $CERTNAME.csr, $CERTNAME.pem and $CERTNAME-key.pem
cfssl gencert -config ../cfssl.json -profile=$CERTPROFILE -ca ../$CATYPE/$CATYPE.pem -ca-key ../$CATYPE/$CATYPE-key.pem csr-$CERTNAME.json | cfssljson -bare $CERTNAME -
# Verify the certificate, if CATYPE=ca.
openssl verify -CAfile ../ca/ca.pem $CERTNAME.pem
# Verify the certificate, if CATYPE=intermediate.
openssl verify -CAfile ../ca/ca.pem -untrusted ../intermediate/intermediate.pem -show_chain -purpose ssl${CERTPROFILE} $CERTNAME.pem
```

## End to end testing

After we have created a pair of certificates, we can test them end-to-end using OpenSSL.

### Server
```bash
SERVER_CERT=my-openvpn-server
# If you are using CA
INTERMEDIATE_CA_FLAG=""
# If you are using Intermediate CA
INTERMEDIATE_CA_FLAG="-cert_chain intermediate/intermediate.pem"
openssl s_server -Verify=1 -verify_return_error -CAfile ca/ca.pem -cert $SERVER_CERT/$SERVER_CERT.pem $INTERMEDIATE_CA_FLAG -key $SERVER_CERT/$SERVER_CERT-key.pem
```

### Client
```bash
CLIENT_CERT=my-openvpn-client
# If you are using CA
INTERMEDIATE_CA_FLAG=""
# If you are using Intermediate CA
INTERMEDIATE_CA_FLAG="-cert_chain intermediate/intermediate.pem"
openssl s_client -verify_return_error -CAfile ca/ca.pem -cert $CLIENT_CERT/$CLIENT_CERT.pem $INTERMEDIATE_CA_FLAG -key $CLIENT_CERT/$CLIENT_CERT-key.pem
```
## (Optional) Create PKCS\#12 certificate chain

```bash
CERTNAME=my-openvpn-server
cd $CERTNAME
# If CATYPE=ca
CERTCHAIN="./$CERTNAME.pem ../ca/ca.pem"
# If CATYPE=intermediate
CERTCHAIN="./$CERTNAME.pem ../intermediate/intermediate.pem ../ca/ca.pem"
# This generates $CERTNAME-chain.p12 . You may set an export password as prompted.
cat $CERTCHAIN | openssl pkcs12 -export -out $CERTNAME-chain.p12 -inkey $CERTNAME-key.pem -in /dev/stdin
```

> [!note]
> OpenSSL 3.0.13 does not support verifying a full chain of PKCS\#12 yet. See [here](https://stackoverflow.com/questions/65204616/why-does-openssl-verify-fail-with-a-certificate-chain-file-while-it-succeeds-wit) , [here](https://serverfault.com/questions/1148261/openssl-ignores-intermediate-certificate-in-pkcs12-file) and [here](https://stackoverflow.com/questions/44375300/openssl-verify-with-chained-ca-and-chained-cert).

## Additional notes

Some important steps are copied here: https://rob-blackbourn.medium.com/how-to-use-cfssl-to-create-self-signed-certificates-d55f76ba5781

OpenSSL CA guide: https://openssl-ca.readthedocs.io/en/latest/index.html