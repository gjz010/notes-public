# Tutorial: Homebrew your own virtual private network on NixOS

We will show how to homebrew your own virtual, private network using [OpenVPN](https://openvpn.net/) on NixOS.


> [!warning]
> This is **NOT** a tutorial about building tunnels across some company fireWALL.

## Objectives

Suppose:

- The server runs on `server.example.com` with default port `1194`.
- The internal LAN of which we expect to access directly on remote machines is `192.168.50.0/24`.
- We assign `192.168.100.0/24` to clients in virtual network.

## Server

```nix
{pkgs, ...}:
let
  vpnSubnet = "192.168.100.0";
  vpnMask = "255.255.255.0";
  # See next chapter for details
  vpnKeys = ./vpn;
  vpnDevice = "tun0";
in
{
  # Configure firewall.
  networking.firewall.allowedUDPPorts = [ 1194 ];
  networking.firewall.allowedTCPPorts = [ 1194 ];
  networking.firewall.trustedInterfaces = [ vpnDevice ];

  environment.systemPackages = [pkgs.openvpn];

  services.openvpn.servers.remote.config = ''
    tls-server
    dev ${vpnDevice}
    server ${vpnSubnet} ${vpnMask}
    ifconfig-pool-persist /var/openvpn-remote.txt
    dh ${vpnKeys}/dh2048.pem
    ca ${vpnKeys}/ca.pem
    cert ${vpnKeys}/server.pem
    key ${vpnKeys}/server-key.pem
    cipher AES-256-CBC
    auth-nocache
    comp-lzo
    keepalive 10 60
    ping-timer-rem
    persist-tun
    persist-key
  '';
}
```

## Certificate-based authentication

We use certificates for authentication since Pre-Shared keys are not cool.

### `ca.pem`, `server.pem` and `server-key.pem`

Certificates can be generated with [cfssl](https://github.com/cloudflare/cfssl). See [[tips/cfssl]].


### `dh2048.pem`

Taken from [here](https://community.openvpn.net/openvpn/wiki/GettingStartedwithOVPN):

```bash
openssl dhparam -out dh2048.pem 2048
```


## Client

Two files are required for our setup:

- OpenVPN client configuration: `server.ovpn`.
- Client certificate: `client.pem` and `client-key.pem`. On Windows a PKCS\#12 `client-chain.p12` is required.

### `server.ovpn`

We inline the `ca.pem` ([[tips/cfssl]]) into our client configuration.

```txt
tls-client
dev tun
remote server.example.com 1194
cipher AES-256-CBC
auth-nocache
keepalive 10 60
resolv-entry infinite
nobind
persist-key
persist-tun
comp-lzo
link-mtu 1557
route 192.168.50.0 255.255.255.0 vpn_gateway
<ca>
[YOUR ca.pem HERE]
</ca>
```

### `client.pem` and `client-key.pem`

You need to generate some client certificates according to [[tips/cfssl]].

> [!warning]
> One client certificate is required for **EVERY** client!

### Linux + NetworkManager

On NixOS the NetworkManager plugin is required:

```nix
{pkgs, ...}:
{
  networking.networkmanager.plugins = [pkgs.networkmanager-openvpn];
}
```


### Windows

OpenVPN on Windows requires the client certificates to be exported as a PKCS\#12 certificate chain, say `client-chain.p12`.

See [[tips/cfssl]].


## Additional notes

NixOS Wiki tutorial: https://nixos.wiki/wiki/OpenVPN



#tutorial #nixos
