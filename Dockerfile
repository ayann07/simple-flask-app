
FROM python:3.12-slim
# start from an official Python image.

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# PYTHONUNBUFFERED=1 makes logs appear immediately in Docker/Kubernetes logs, instead of being delayed.

WORKDIR /app
# This creates /uses/app inside the container and makes it the working directory.

COPY requirements.txt .
# Copies your local requirements.txt into the container

RUN pip install --no-cache-dir -r requirements.txt
# Installs your Python dependencies.
# --no-cache-dir keeps the Docker image smaller by not saving pip’s package cache.

COPY app.py .
# Copies your Flask app into the container:

EXPOSE 5000
# Documents that the app listens on port 5000.
# This does not publish the port by itself. It just tells Docker/Kubernetes, “this container expects traffic on port 5000.”

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
# This is the command that runs when the container starts.
# It starts gunicorn, a production-ready Python web server.


# The Dockerfile is the recipe for packaging your Flask app into a container image.
# Azure Kubernetes Service cannot directly run those files. Kubernetes runs containers. So the flow is:

# Flask code
#    ↓
# Dockerfile builds image
#    ↓
# Image pushed to Azure Container Registry
#    ↓
# Kubernetes pulls image
#    ↓
# AKS runs your app as Pods