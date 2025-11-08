#!/usr/bin/env bash
set -e
PROJECT=${PROJECT:-$(gcloud config get-value project)}
REGION=${REGION:-us-central1}
REPO=${REPO:-hackathon-repo}
TAG=${TAG:-latest}
CLUSTER=${CLUSTER:-hack-gke-cluster}
ZONE=${ZONE:-us-east1-b}

cd "$(dirname "$0")/.."
sed -i "s|__IMAGE_PATIENT__|${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/patient-service:${TAG}|g" k8s/*.yaml
sed -i "s|__IMAGE_APPOINTMENT__|${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/application-service:${TAG}|g" k8s/*.yaml
sed -i "s|__IMAGE_ORDER__|${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/order-service:${TAG}|g" k8s/*.yaml

gcloud container clusters get-credentials "${CLUSTER}" --zone "${ZONE}" --project "${PROJECT}"
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/patient-deployment.yaml
kubectl apply -f k8s/application-deployment.yaml
kubectl apply -f k8s/order-deployment.yaml
echo "Deployment applied. Run: kubectl get pods -n hackathon && kubectl get svc -n hackathon"
