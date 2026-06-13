#!/usr/bin/env bash

set -euo pipefail

ACR_NAME="${ACR_NAME:-ayansimpleflaskacr}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-ayansimpleflaskacr.azurecr.io}"
IMAGE_NAME="${IMAGE_NAME:-simple-flask-app}"
CHART_DIR="${CHART_DIR:-./k8s-helm}"
PLATFORM="${PLATFORM:-linux/amd64}"

ENVIRONMENT="${1:-prod}"
TAG="${2:-$(date +%Y%m%d%H%M%S)}"

case "${ENVIRONMENT}" in
  prod)
    RELEASE_NAME="${RELEASE_NAME:-simple-flask-app}"
    NAMESPACE="${NAMESPACE:-simple-flask-prod}"
    VALUES_FILE="${VALUES_FILE:-k8s-helm/values/prod.yaml}"
    ;;
  stage)
    RELEASE_NAME="${RELEASE_NAME:-simple-flask-app-stage}"
    NAMESPACE="${NAMESPACE:-simple-flask-stage}"
    VALUES_FILE="${VALUES_FILE:-k8s-helm/values/stage.yaml}"
    ;;
  *)
    echo "Usage: $0 [prod|stage] [image-tag]" >&2
    exit 1
    ;;
esac

IMAGE="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${TAG}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command az
require_command docker
require_command helm
require_command kubectl

echo "Environment: ${ENVIRONMENT}"
echo "Namespace: ${NAMESPACE}"
echo "Release: ${RELEASE_NAME}"
echo "Values file: ${VALUES_FILE}"

echo "Logging in to ACR: ${ACR_NAME}"
az acr login --name "${ACR_NAME}"

echo "Building and pushing image: ${IMAGE}"
docker buildx build \
  --platform "${PLATFORM}" \
  -t "${IMAGE}" \
  --push .

echo "Deploying Helm release: ${RELEASE_NAME}"
kubectl create namespace "${NAMESPACE}" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
  -f "${VALUES_FILE}" \
  --namespace "${NAMESPACE}" \
  --set "image.repository=${ACR_LOGIN_SERVER}/${IMAGE_NAME}" \
  --set "image.tag=${TAG}"

echo "Waiting for rollout"
kubectl rollout status "deployment/${RELEASE_NAME}" \
  --namespace "${NAMESPACE}"

echo "Redeployed ${IMAGE}"
