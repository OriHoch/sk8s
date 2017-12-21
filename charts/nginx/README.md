# Nginx subchart

Provides advanced reverse proxy / services not provided by Traefik.


## enable HTTP authentication

You should configure a traefik backend that points to the nginx pod on a specific port number, then update `nginx-conf.yaml` to handle that port number with http auth enabled.

To add a user to the htpasswd file:

```
htpasswd ./secret-nginx-htpasswd superadmin
```

(use `-c` if you are just creating the file)

set the file as a secret on k8s:

```
kubectl create secret generic nginx-htpasswd --from-file=./secret-nginx-htpasswd
```

Update the value in `environments/ENVIRONMENT_NAME/values.yaml`:

```
nginx:
  htpasswdSecretName: nginx-htpasswd
```
