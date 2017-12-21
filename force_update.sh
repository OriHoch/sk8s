#!/usr/bin/env bash

# force an update for a K8S deployment by setting a label with unix timestamp

source connect.sh

[ "${1}" == "" ] && echo "usage: ./force_update.sh <deployment_name>" && exit 1
! kubectl patch deployment "${1}" -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"date\":\"`date +'%s'`\"}}}}}" && exit 1
kubectl rollout status deployment "${1}"
