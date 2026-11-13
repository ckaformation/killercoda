#!/bin/bash
NS="hoth"
OLD_PVC="echo-base-data"

CLAIM=$(kubectl get deployment echo-base -n "$NS" -o jsonpath='{range .spec.template.spec.volumes[*]}{.persistentVolumeClaim.claimName}{"\n"}{end}' 2>/dev/null | grep -v '^$' | head -n1)
if [ -z "$CLAIM" ] || [ "$CLAIM" = "$OLD_PVC" ]; then
  echo "❌ Le déploiement echo-base doit pointer vers le nouveau PVC (trouvé: '$CLAIM')"
  exit 1
fi

SC=$(kubectl get pvc "$CLAIM" -n "$NS" -o jsonpath='{.spec.storageClassName}' 2>/dev/null)
if [ "$SC" != "retain-storage" ]; then
  echo "❌ Le PVC référencé ($CLAIM) n'utilise pas la StorageClass retain-storage (trouvé: '$SC')"
  exit 1
fi
echo "✅ Deployment pointe vers le PVC $CLAIM (retain-storage)"

echo "Attente de la stabilisation du Deployment..."
if ! kubectl -n "$NS" rollout status deployment/echo-base --timeout=90s; then
  echo "❌ Le pod echo-base n'est pas Running/Ready"
  exit 1
fi
echo "✅ Pod echo-base Running/Ready"

if kubectl get job migrate-data -n "$NS" >/dev/null 2>&1; then
  echo "❌ Le Job migrate-data existe encore, il devait être supprimé"
  exit 1
fi
echo "✅ Job supprimé"

if kubectl get pvc "$OLD_PVC" -n "$NS" >/dev/null 2>&1; then
  echo "❌ L'ancien PVC $OLD_PVC existe encore, il devait être supprimé"
  exit 1
fi
echo "✅ Ancien PVC supprimé"

exit 0
