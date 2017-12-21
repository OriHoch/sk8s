#!/usr/bin/env bash

#
# This script can be used to update Helm configuration values for specific environments
#
# This method works under the following conditions:
#
#   * You want to make changes to a main / shared environment (e.g. production / staging) - otherwise, just do a helm upgrade.
#   * You want to modify a specific value in a specific resource (usually a deployment image, but other values are possible too)
#   * This value is represented in the Helm configuration values
#
# This script accepts a single required argument - a json string containing the required update
#
# It updates the values in the current environment's auto updated values file - environments/ENVIRONMENT_NAME/values.auto-updated.yaml
#
# for example, the following command will update the image value under the spark key.
#
# ./helm_update_values.sh '{"spark":{"image":"'${IMAGE_TAG}'"}}'
#
# Json values require quotes which may interfere with bash scripts, so you can provide it base64 encoded
#
# B64_UPDATE_VALUES=`echo '{"spark":{"image":"'${IMAGE_TAG}'"}}' | base64 -w0`
# ./helm_update_values.sh $B64_UPDATE_VALUES
#
# After ther values were updated, they should be pushed to GitHub
#
# It's important to commit the changes to Git **first** and only then patch the deployment - this prevents infrastrcuture conflicts.
#
# This script also supports updating Git from CI tools
#
# Create a [GitHub machine user](https://developer.github.com/v3/guides/managing-deploy-keys/#machine-users) and give this user write permissions to the k8s repo.
#
# Run the script with the full parameters:
#
# ./helm_update_values.sh <YAML_OVERRIDE_VALUES_JSON> [GIT_COMMIT_MESSAGE] [GIT_REPO_TOKEN] [GIT_REPO_SLUG] [GIT_REPO_BRANCH]
#
# Where GIT_REPO_TOKEN is the machine user's token
#
# After GitHub was updated, patch the deployment, for example, in case of image update:
#
# kubectl set image deployment/spark spark=${IMAGE_TAG}

source connect.sh

if [ "${1}" == "" ]; then
    echo "Usage: ./helm_update_values.sh <YAML_OVERRIDE_VALUES_JSON> [GIT_COMMIT_MESSAGE] [GIT_REPO_TOKEN] [GIT_REPO_SLUG] [GIT_REPO_BRANCH]"
fi

YAML_OVERRIDE_VALUES_JSON="${1}"
GIT_COMMIT_MESSAGE="${2}"
GIT_REPO_TOKEN="${3}"
GIT_REPO_SLUG="${4}"
GIT_REPO_BRANCH="${5:-master}"

if [ "${YAML_OVERRIDE_VALUES_JSON:0:1}" != '{' ]; then
    ! YAML_OVERRIDE_VALUES_JSON=`echo "${YAML_OVERRIDE_VALUES_JSON}" | base64 -d` \
        && echo "failed to decode the override values" && exit 1
fi

[ "${YAML_OVERRIDE_VALUES_JSON:0:1}" != '{' ] && echo "invalid override values" && exit 1

echo "Updating values for ${K8S_ENVIRONMENT_NAME} environment: ${YAML_OVERRIDE_VALUES_JSON}"

! ./update_yaml.py "${YAML_OVERRIDE_VALUES_JSON}" "environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml" &&\
    echo "Failed to update environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml" && exit 1

if [ "${GIT_COMMIT_MESSAGE}" != "" ] && [ "${GIT_REPO_TOKEN}" != "" ] && [ "${GIT_REPO_SLUG}" != "" ]; then
    echo "Committing and pushing to Git"
    TEMPDIR=`mktemp -d`

    ! (
        git config user.email "deployment-bot@${K8S_ENVIRONMENT_NAME}" &&
        git config user.name "${K8S_ENVIRONMENT_NAME}-deployment-bot"
    ) && echo "failed to git config" && exit 1

    ! git clone --depth 1 --branch "${GIT_REPO_BRANCH}" "https://github.com/${GIT_REPO_SLUG}.git" "${TEMPDIR}" \
      && echo "failed git clone" && exit 1

    if ! git diff --shortstat --exit-code "environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml"; then
        echo "Committing and pushing changes in environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml"
        ! (
            git add "environments/${K8S_ENVIRONMENT_NAME}/values.auto-updated.yaml" &&\
            git commit -m "${GIT_COMMIT_MESSAGE}" &&\
            git push https://${GIT_REPO_TOKEN}'@'github.com/${GIT_REPO_SLUG}.git "${GIT_REPO_BRANCH}"
        ) && echo "failed to push changes" && exit 1
    else
        echo "No changes, skipping commit / push"
    fi
    rm -rf "${TEMPDIR}"
fi

echo "Great Success!"
exit 0
