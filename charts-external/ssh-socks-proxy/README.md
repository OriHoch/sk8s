# Ssh socks proxy subchart

Runs a socks proxy via an ssh server


## Provisioning the required resources

Create an ssh key which will be stored as a kubernetes secret for authentication with the proxy server

```
ssh-keygen -t rsa -b 4096 -C "${K8S_HELM_RELEASE_NAME}-${K8S_ENVIRONMENT_NAME}-ssh-socks-proxy" \
                          -f "environments/${K8S_ENVIRONMENT_NAME}/secret-ssh-socks-proxy.key" \
                          -N "" -q
```

Authenticate the key on the remote server, dedicated for the socks proxy

```
PUBKEY=`cat "environments/${K8S_ENVIRONMENT_NAME}/secret-ssh-socks-proxy.key.pub"`
AUTHORIZED_KEY='no-agent-forwarding,no-X11-forwarding,command="read a; exit" '"${PUBKEY}"
echo "${AUTHORIZED_KEY}" | ssh user@server 'cat >> .ssh/authorized_keys'
```

Set the kubernetes secrets

```
kubectl create secret generic ssh-socks-proxy \
        --from-literal=SSH_B64_KEY=`cat "environments/${K8S_ENVIRONMENT_NAME}/secret-ssh-socks-proxy.key" | base64 -w0` \
        --from-literal=SSH_B64_PUBKEY=`cat "environments/${K8S_ENVIRONMENT_NAME}/secret-ssh-socks-proxy.key.pub" | base64 -w0`
```

Enable the values

```
ssh-socks-proxy:
  enabled: true
  ssh_host: user@server
  ssh_port: '22'
```

Proxy is available at `socks5h://ssh-socks-proxy:8123`
