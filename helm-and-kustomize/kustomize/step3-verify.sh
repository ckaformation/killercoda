#!/bin/bash
BASE_DIR="/root/kustomize-multi-region/base"

if grep -q "service.yaml" "$BASE_DIR/kustomization.yaml" 2>/dev/null; then
  echo "❌ base/kustomization.yaml référence encore service.yaml"
  exit 1
fi
echo "✅ base ne référence plus service.yaml"

for NS in europe-west1 us-west1; do
  if kubectl get svc region-service -n "$NS" >/dev/null 2>&1; then
    echo "❌ Le service region-service existe encore dans $NS"
    exit 1
  fi
  echo "✅ Aucun service region-service dans $NS"

  echo "Attente de la stabilisation du Deployment dans $NS..."
  if ! kubectl -n "$NS" rollout status deployment/region-service --timeout=60s; then
    echo "❌ Le déploiement dans $NS n'est pas Running/Ready"
    exit 1
  fi
  echo "✅ Déploiement toujours sain dans $NS"
done

exit 0
