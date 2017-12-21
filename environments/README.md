# Environments

Each sub-directory corresponds to an environment.


## Create a new environment

Each environment should have the following files:

- `environments/ENVIRONMENT_NAME/.env`: the basic environment connection details
- `environments/ENVIRONMENT_NAME/values.yaml`: override default helm chart values for this environment
- `environments/ENVIRONMENT_NAME/values.auto-updated.yaml`: override environment values from automatically updated actions (e.g. continuous deployment)
- `environments/ENVIRONMENT_NAME/secrets.sh`: create the secrets for this environment, shouldn't be committed to Git.

You can copy from `staging` environment and modify. For a new cluster you should delete the K8S_ENVIRONMENT_CONTEXT variable - it will be added automatically.

You don't have to create a new cluster for each environment, you can use namespaces to differentiate between environments and keep everything on a single cluster.

If you are using an existing cluster, skip to "once the cluster is running" below

Get the available Kubernetes versions:

```
gcloud --project=<GOOGLE_PROJECT_ID> container get-server-config --zone=us-central1-a
```

Create a cluster (modify version to latest from previous command):

```
gcloud --project=<GOOGLE_PROJECT_ID> container clusters create --zone=us-central1-a <CLUSTER_NAME> \
                                                               --cluster-version=1.8.4-gke.0 \
                                                               --num-nodes=1
```

Once the cluster is running, connect to the environment:

```
source switch_environment.sh ENVIRONMENT_NAME
```

Install helm and tiller

```
kubectl create -f rbac-config.yaml
helm init --service-account tiller
```


## Delete an environment and related resources

```
helm delete "${K8S_HELM_RELEASE_NAME}" --purge
```
