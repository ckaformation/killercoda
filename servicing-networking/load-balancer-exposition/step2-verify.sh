#!/bin/bash
if ! kubectl get hpa holonet >/dev/null 2>&1; then
  echo "Le HPA holonet n'existe pas encore."
  exit 1
fi

MIN=$(kubectl get hpa holonet -o jsonpath='{.spec.minReplicas}' 2>/dev/null)
if [ "$MIN" != "2" ]; then
  echo "minReplicas devrait être 2 (obtenu: '$MIN')."
  exit 1
fi

MAX=$(kubectl get hpa holonet -o jsonpath='{.spec.maxReplicas}' 2>/dev/null)
if [ "$MAX" != "4" ]; then
  echo "maxReplicas devrait être 4 (obtenu: '$MAX')."
  exit 1
fi

# Robuste aux deux formats possibles (autoscaling/v2 vs l'ancien v1)
TARGET_V2=$(kubectl get hpa holonet -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null)
TARGET_V1=$(kubectl get hpa holonet -o jsonpath='{.spec.targetCPUUtilizationPercentage}' 2>/dev/null)
TARGET="${TARGET_V2:-$TARGET_V1}"
if [ "$TARGET" != "50" ]; then
  echo "La cible d'utilisation CPU moyenne devrait être 50 (obtenu: '$TARGET')."
  exit 1
fi

REF_NAME=$(kubectl get hpa holonet -o jsonpath='{.spec.scaleTargetRef.name}' 2>/dev/null)
if [ "$REF_NAME" != "holonet" ]; then
  echo "Le HPA devrait cibler le Deployment holonet (obtenu: '$REF_NAME')."
  exit 1
fi

echo "Le HPA holonet est correctement configuré : min=2, max=4, cpu averageUtilization=50%, cible le Deployment holonet."
exit 0
