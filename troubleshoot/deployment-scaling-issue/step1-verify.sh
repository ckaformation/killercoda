#!/bin/bash
NS="kessel-run"
DEPLOY="millennium-falcon"

HPA_NAME=$(kubectl get hpa -n "$NS" -o jsonpath="{.items[?(@.spec.scaleTargetRef.name=='$DEPLOY')].metadata.name}" 2>/dev/null | awk '{print $1}')
if [ -z "$HPA_NAME" ]; then
  echo "❌ Aucun HPA trouvé pour le déploiement $DEPLOY"
  exit 1
fi
echo "✅ HPA trouvé : $HPA_NAME"

MIN=$(kubectl get hpa "$HPA_NAME" -n "$NS" -o jsonpath='{.spec.minReplicas}')
MAX=$(kubectl get hpa "$HPA_NAME" -n "$NS" -o jsonpath='{.spec.maxReplicas}')
if [ "$MIN" != "10" ] || [ "$MAX" != "20" ]; then
  echo "❌ min/max attendus 10/20, trouvés '$MIN'/'$MAX'"
  exit 1
fi
echo "✅ min=10, max=20"

TARGET=$(kubectl get hpa "$HPA_NAME" -n "$NS" -o jsonpath='{.spec.metrics[?(@.resource.name=="cpu")].resource.target.averageUtilization}' 2>/dev/null)
if [ -z "$TARGET" ]; then
  TARGET=$(kubectl get hpa "$HPA_NAME" -n "$NS" -o jsonpath='{.spec.targetCPUUtilizationPercentage}' 2>/dev/null)
fi
if [ "$TARGET" != "60" ]; then
  echo "❌ Cible CPU attendue 60, trouvée '$TARGET'"
  exit 1
fi
echo "✅ Cible CPU 60%"

exit 0
