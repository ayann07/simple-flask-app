# simple-flask-app

Simple Flask application packaged with Docker and Kubernetes manifests for deployment to Azure Kubernetes Service.

## Local container

```bash
docker build -t simple-flask-app:v1 .
docker run --rm -p 5000:5000 simple-flask-app:v1
```

Open:

```text
http://localhost:5000
```

## Deploy to Azure AKS

Set these values first:

```bash
RESOURCE_GROUP=simple-flask-rg
LOCATION=eastus
ACR_NAME=<unique-acr-name>
AKS_NAME=simple-flask-aks
IMAGE_NAME=simple-flask-app
IMAGE_TAG=v1
```

Create Azure resources:

```bash
az login
az group create --name $RESOURCE_GROUP --location $LOCATION
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count 1 \
  --enable-managed-identity \
  --attach-acr $ACR_NAME \
  --generate-ssh-keys
```

Build and push the image to Azure Container Registry:

```bash
az acr build \
  --registry $ACR_NAME \
  --image $IMAGE_NAME:$IMAGE_TAG .
```

Connect kubectl to AKS:

```bash
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME
```

Update the Kubernetes image placeholder:

```bash
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
sed -i.bak "s|<ACR_LOGIN_SERVER>|$ACR_LOGIN_SERVER|g" k8s/deployment.yaml
```

Deploy:

```bash
kubectl apply -f k8s/
kubectl get pods
kubectl get service simple-flask-app
```

When the service shows an `EXTERNAL-IP`, open:

```text
http://<EXTERNAL-IP>
```

## CI/CD with GitHub Actions

The workflow in `.github/workflows/deploy.yml` builds the Docker image, pushes it
to ACR, and deploys the Helm chart to AKS.

- Push to `develop` deploys `stage`.
- Push to `main` deploys `prod`.
- You can also run the workflow manually and choose `stage` or `prod`.

Create one GitHub repository secret named `AZURE_CREDENTIALS`.

```bash
az ad sp create-for-rbac \
  --name github-simple-flask-cicd \
  --role contributor \
  --scopes /subscriptions/fd8b56b8-9346-40dd-982a-5b4f7fe30cfd/resourceGroups/simple-flask-rg \
  --sdk-auth
```

Copy the JSON output into:

```text
GitHub repo -> Settings -> Secrets and variables -> Actions -> New repository secret
```

Use this secret name:

```text
AZURE_CREDENTIALS
```

Then give the service principal permission to push images to ACR. Use the
`clientId` value from the JSON output above:

```bash
APP_ID=<clientId-from-AZURE_CREDENTIALS-json>
ACR_ID=$(az acr show --name ayansimpleflaskacr --query id --output tsv)

az role assignment create \
  --assignee "$APP_ID" \
  --role AcrPush \
  --scope "$ACR_ID"
```
