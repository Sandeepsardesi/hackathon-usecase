# Hackathon Usecase — DevOps Repo

## Overview
Three microservices:
- patient-service (Node, port 3000)
- application-service (Node, port 3001)
- order-service (Spring Boot, port 8080)

## Quick start
1. Build & run locally:
   - patient: cd patient-service && npm install && node src/index.js
   - application: cd application-service && npm install && node src/index.js
   - order: cd order-service && mvn -DskipTests package && java -jar target/*.jar

2. Build & push images (GCP):
   - gcloud auth login && gcloud config set project <PROJECT_ID>
   - ./scripts/build-and-push.sh

3. Deploy to GKE:
   - Ensure cluster exists and you have permissions.
   - Adjust env in scripts if needed.
   - ./scripts/deploy-k8s.sh

## CI/CD
- Workflow: .github/workflows/ci-cd.yml
- GitHub Secrets required:
  - GCP_SA_KEY (JSON service account)
  - GCP_PROJECT
