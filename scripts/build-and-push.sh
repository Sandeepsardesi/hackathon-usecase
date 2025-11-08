#!/usr/bin/env bash
set -e
PROJECT=${PROJECT:-$(gcloud config get-value project)}
REGION=${REGION:-us-central1}
REPO=${REPO:-hackathon-repo}
TAG=${TAG:-latest}

echo "Project=$PROJECT Region=$REGION Repo=$REPO Tag=$TAG"

gcloud artifacts repositories describe ${REPO} --location=${REGION} --project=${PROJECT} >/dev/null 2>&1 || \
  gcloud artifacts repositories create ${REPO} --repository-format=docker --location=${REGION} --description="Hackathon images" --project=${PROJECT}

# patient
gcloud builds submit --project="${PROJECT}" --region="${REGION}" --tag=${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/patient-service:${TAG} ./patient-service

# application
gcloud builds submit --project="${PROJECT}" --region="${REGION}" --tag=${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/application-service:${TAG} ./application-service

# order: build jar then build image
(cd order-service && mvn -DskipTests package)
gcloud builds submit --project="${PROJECT}" --region="${REGION}" --tag=${REGION}-docker.pkg.dev/${PROJECT}/${REPO}/order-service:${TAG} ./order-service
