#!/usr/bin/env bash
set -euo pipefail

# This script inserts a readiness, liveness and resource block
# after the first `containerPort: <N>` line in each deployment YAML under k8s/.
# It creates *.patched backup files and leaves originals intact.

for f in k8s/*.yaml; do
  [ -f "$f" ] || continue
  # Only operate on files that look like a Deployment (simple check)
  if ! grep -q "kind: *Deployment" "$f"; then
    echo "Skipping $f (not a Deployment)"
    continue
  fi

  echo "Patching $f -> ${f}.patched"
  awk '
    BEGIN { inserted=0; inside_containers=0; port=0 }
    {
      print $0
      # detect entering containers: block
      if ($0 ~ /^[[:space:]]*containers:[[:space:]]*$/) { inside_containers=1; next }
      # if inside containers block and we find containerPort: N (first occurrence),
      # capture indentation and port then insert the probe block once.
      if (inside_containers && inserted==0 && $0 ~ /^[[:space:]]*containerPort:[[:space:]]*[0-9]+[[:space:]]*$/) {
        indent = gensub(/^([[:space:]]*).*/,"\\1","g",$0)
        # extract the port number
        match($0, /[0-9]+/)
        port = substr($0, RSTART, RLENGTH)
        # print the probe + resources block with the same base indent
        print indent "readinessProbe:"
        print indent "  httpGet:"
        print indent "    path: /health"
        print indent "    port: " port
        print indent "  initialDelaySeconds: 5"
        print indent "  periodSeconds: 10"
        print indent "  failureThreshold: 3"
        print indent "  successThreshold: 1"
        print indent "livenessProbe:"
        print indent "  httpGet:"
        print indent "    path: /health"
        print indent "    port: " port
        print indent "  initialDelaySeconds: 30"
        print indent "  periodSeconds: 20"
        print indent "  failureThreshold: 5"
        print indent "resources:"
        print indent "  requests:"
        print indent "    cpu: 100m"
        print indent "    memory: 128Mi"
        print indent "  limits:"
        print indent "    cpu: 500m"
        print indent "    memory: 512Mi"
        inserted=1
      }
      # if we exit the containers block, mark it
      if (inside_containers && $0 ~ /^[[:space:]]*-[[:space:]]*name:/) { inside_containers=1 }
      if (inside_containers && $0 ~ /^[[:space:]]*-[[:space:]]*image:/) { inside_containers=1 }
      # crude end of containers detection: next top-level key
      if (inside_containers && $0 ~ /^[^[:space:]]/ && $0 !~ /^[[:space:]]/) { inside_containers=0 }
    }
  ' "$f" > "${f}.patched"

  # If patched file contains the inserted block (simple check), replace original
  if grep -q "readinessProbe:" "${f}.patched"; then
    mv "${f}.patched" "$f"
    echo "Updated $f"
  else
    echo "No insertion made for $f (maybe port pattern not found). Removing .patched"
    rm -f "${f}.patched"
  fi
done
