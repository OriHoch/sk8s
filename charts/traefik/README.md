# Traefik subchart

we use [traefik](https://traefik.io/) as the main app entrypoint

It provides app load balancing and automatic SSL using Let's encrypt.


## Enabling SSL

For a basic single domain configuration, you can use the provided traefik-etc configuration

You just need to set:

```
traefik:
  acmeEmail: <EMAIL_FOR_CERTIFICATE_REGISTRATION>
  rootDomain: <DOMAIN_TO_GENERATE_AND_RENEW_CERTIFICATES_FOR>
```


## Shared Host for Let's encrypt

We use a shared host path for let's encrypt certificates and renewals

On initial deployment you should not set the traefik `nodeHostName`

After the pod is scheduled, check the node traefik is on:

```
kubectl describe pod traefik-<TAB><TAB>
```

And update in values

```
traefik:
  nodeHostName: <NODE_HOST_NAME>
```

Alternatively, you can use `nodePool` in case you have a pool with just one node.


## Static IP for the load balancer

Reserve a static IP:

```
gcloud compute addresses create ENVIRONMENT_NAME-traefik --region=us-central1
```

Get the static IP address:

```
gcloud compute addresses describe ENVIRONMENT_NAME-traefik --region=us-central1 | grep ^address:
```

Update in `environments/ENVIRONMENT_NAME/values.yaml`:

```
traefik:
  loadBalancerIP: <THE_STATIC_IP>
```


## Using DNS solver for SSL certificates

By default an http solver is used to issue SSL certificates, this doesn't always work.

To ensure you will always get and renew certificates you should change to a dns solver.

You need to set the `dnsProvider` in `[acme]` section of `traefik.toml` and corresponding DNS provider keys

See https://docs.traefik.io/configuration/acme/#dnsprovider

If you dns provider is not supported, you can setup a free [Cloudflare](https://www.cloudflare.com/) account