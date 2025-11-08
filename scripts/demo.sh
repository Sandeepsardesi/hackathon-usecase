#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=hackathon

echo "Applying k8s manifests..."
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/application-deployment.yaml
kubectl apply -f k8s/patient-deployment.yaml
kubectl apply -f k8s/order-deployment.yaml

echo "Waiting for rollouts..."
kubectl rollout status deploy/application-deployment -n ${NAMESPACE} --timeout=120s
kubectl rollout status deploy/patient-deployment -n ${NAMESPACE} --timeout=120s
kubectl rollout status deploy/order-deployment -n ${NAMESPACE} --timeout=120s

echo "Services:"
kubectl get svc -n ${NAMESPACE} -o wide

echo "Pods:"
kubectl get pods -n ${NAMESPACE} -o wide

echo "Health checks (via port-forward to localhost for a short time):"
kubectl port-forward -n ${NAMESPACE} svc/patient-lb 8080:80 &
PF1=$!
sleep 1
curl -sS http://localhost:8080/health || echo "patient /health no response"
kill $PF1 || true

kubectl port-forward -n ${NAMESPACE} svc/application-lb 8081:80 &
PF2=$!
sleep 1
curl -sS http://localhost:8081/health || echo "application /health no response"
kill $PF2 || true

echo "Demo complete."
