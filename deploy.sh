#!/usr/bin/env bash
#!Tells the system to execute this script using the Bash shell.

set -euo pipefail
# set -euo pipefail: This is a crucial safety measure in Bash scripting (often called "strict mode").

# -e: Exits the script immediately if any command fails (returns a non-zero exit status).

# -u: Exits the script if you try to use an undeclared variable.

# -o pipefail: Ensures that if a command in a pipeline fails, the whole pipeline fails (by default, Bash only looks at the exit code of the last command in a pipeline).

ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-ayansimpleflaskacr.azurecr.io}"
IMAGE_NAME="${IMAGE_NAME:-simple-flask-app}"
DEPLOYMENT_NAME="${DEPLOYMENT_NAME:-simple-flask-app}"
CONTAINER_NAME="${CONTAINER_NAME:-simple-flask-app}"
NAMESPACE="${NAMESPACE:-simple-flask-prod}"
PLATFORM="${PLATFORM:-linux/amd64}"
TAG="${1:-$(date +%Y%m%d%H%M%S)}"

IMAGE="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${TAG}"
# The script defines several configuration variables using the syntax ${VARIABLE_NAME:-default_value}. This means it will use the existing environment variable if it's set; otherwise, it falls back to the provided default.

# ACR_LOGIN_SERVER: The URL of your Azure Container Registry (defaults to ayansimpleflaskacr.azurecr.io).

# IMAGE_NAME, DEPLOYMENT_NAME, CONTAINER_NAME: Default to simple-flask-app.

# NAMESPACE: The Kubernetes namespace (defaults to simple-flask-prod).

# PLATFORM: The target CPU architecture for the Docker image (defaults to linux/amd64).

# TAG: The image version tag. It checks if you passed an argument when running the script ($1). If not, it generates a unique timestamp based on the current date and time (e.g., 20260531133124).

# IMAGE: Combines the registry, image name, and tag into the full image path (e.g., ayansimpleflaskacr.azurecr.io/simple-flask-app:20260531133124).

if [[ "${SKIP_CONFIRM:-}" != "true" ]]; then
  read -r -p "Deploy ${IMAGE} to ${NAMESPACE}/${DEPLOYMENT_NAME}? Type yes to continue: " CONFIRM
  if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Deployment cancelled."
    exit 0
  fi
fi

echo "Building and pushing ${IMAGE}"
docker buildx build \
  --platform "${PLATFORM}" \
  -t "${IMAGE}" \
  --push .
# This uses Docker Buildx (which supports multi-architecture builds) to build the Dockerfile in your current directory (.).

# -t "${IMAGE}": Tags the build with the full registry URL and version tag.

# --push: Automatically pushes the image to your Azure Container Registry as soon as the build finishes.
echo "Updating Kubernetes deployment ${DEPLOYMENT_NAME}"
kubectl set image "deployment/${DEPLOYMENT_NAME}" \
  "${CONTAINER_NAME}=${IMAGE}" \
  --namespace "${NAMESPACE}"
# This command tells your Kubernetes cluster to update the specified deployment. It changes the image of the container named simple-flask-app to the brand new image you just built and pushed.

echo "Waiting for rollout to finish"
kubectl rollout status "deployment/${DEPLOYMENT_NAME}" \
  --namespace "${NAMESPACE}"

echo "Deployed ${IMAGE}"
# Finally, the script waits and watches the Kubernetes rollout process. It ensures the new pods start up successfully and the old ones terminate before printing the final success message: Deployed ${IMAGE}.
