#!/usr/bin/env bash
set -euo pipefail

PROJECT=${PROJECT:-empyrean-backup-477606-k8}
REGION=${REGION:-us-central1}
REPO=${REPO:-hackathon-repo}
TAG=${TAG:-latest}
NS=${NS:-hackathon}

echo "Project: $PROJECT"
echo "Artifact Registry images:"
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT}/${REPO} --project=${PROJECT} || true
echo

echo "Kubernetes Services in namespace $NS:"
kubectl get svc -n ${NS} -o wide || true
echo

echo "External IPs (curl health endpoints):"
PATIENT_IP=$(kubectl get svc patient-lb -n ${NS} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
APP_IP=$(kubectl get svc application-lb -n ${NS} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
ORDER_IP=$(kubectl get svc order-lb -n ${NS} -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)

echo "patient-lb: $PATIENT_IP"
echo "application-lb: $APP_IP"
echo "order-lb: $ORDER_IP"
echo

echo "Testing endpoints (first try external IPs):"
if [ -n "$PATIENT_IP" ]; then
  echo -n "Patient /health -> "
  curl -sS http://$PATIENT_IP/health || echo "FAILED"
fi

if [ -n "$APP_IP" ]; then
  echo -n "Application /health -> "
  curl -sS http://$APP_IP/health || echo "FAILED"
fi

if [ -n "$ORDER_IP" ]; then
  echo -n "Order /actuator/health -> "
  curl -sS http://$ORDER_IP/actuator/health || echo "FAILED or 404"
fi

echo
echo "If external IPs are not available or you want local testing, run (in Cloud Shell):"
echo "  kubectl port-forward -n ${NS} svc/patient-lb 8080:80 &"
echo "  kubectl port-forward -n ${NS} svc/application-lb 8081:80 &"
echo "  kubectl port-forward -n ${NS} svc/order-lb 8082:80 &"
echo "then curl http://localhost:8080/health , http://localhost:8081/health , http://localhost:8082/actuator/health"
