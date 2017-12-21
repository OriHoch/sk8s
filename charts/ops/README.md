# Ops

Allows to run management commands and interact with the environment from CI / automation scripts / scheduled jobs.

Interacting with the environment securely requires a service account key with relevant permissions


## Secrets

Assuming you have the key file at `environments/${K8S_ENVIRONMENT_NAME}/secret-k8s-ops.json`:

```
! kubectl describe secret ops &&\
  kubectl create secret generic ops "--from-file=secret.json=environments/${K8S_ENVIRONMENT_NAME}/secret-k8s-ops.json"
```

Set in values

```
ops:
  secret: ops
```


## Build and publish the docker ops image

If you don't require additional dependencies you can use `orihoch/sk8s` image on public docker hub, in this case skip to set in values below.

Otherwise, you should build the ops image and publish yourself.

The ops image only contains the system dependencies, the code and configurations are pulled directory from Git - so you shouldn't need to update it often.

You can use google container builder service to build the image

```
gcloud container builds submit --tag gcr.io/${CLOUDSDK_CORE_PROJECT}/sk8s charts/ops
```

pull, tag and push to public docker hub

```
gcloud docker -- pull gcr.io/${CLOUDSDK_CORE_PROJECT}/sk8s
docker tag gcr.io/${CLOUDSDK_CORE_PROJECT}/sk8s orihoch/sk8s
docker push orihoch/sk8s
```

Set in values

```
ops:
  image: orihoch/sk8s@sha256:5660a773e64b6ec495f4f5f62211bd85ceb3452e9372f8a7a270c112804b03f3
```


## Creating a new service account with full permissions and related key file

This will create a key file at `environments/ENVIRONMENT_NAME/secret-k8s-ops.json` - it should not be committed to Git.

```
export SERVICE_ACCOUNT_NAME="k8s-ops"
export SERVICE_ACCOUNT_ID="${SERVICE_ACCOUNT_NAME}@${CLOUDSDK_CORE_PROJECT}.iam.gserviceaccount.com"

! gcloud iam service-accounts list | grep "${SERVICE_ACCOUNT_ID}" &&\
    gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}"

! [ -f "environments/${K8S_ENVIRONMENT_NAME}/secret-k8s-ops.json" ] &&\
    gcloud iam service-accounts keys create "--iam-account=${SERVICE_ACCOUNT_ID}" \
                                            "environments/${K8S_ENVIRONMENT_NAME}/secret-k8s-ops.json"

gcloud projects add-iam-policy-binding --role "roles/storage.admin" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/cloudbuild.builds.editor" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/container.admin" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
gcloud projects add-iam-policy-binding --role "roles/viewer" "${CLOUDSDK_CORE_PROJECT}" \
                                       --member "serviceAccount:${SERVICE_ACCOUNT_ID}"
```
