#!/bin/bash
D="snowspeeder"

kubectl get deployment "$D" >/dev/null 2>&1 || { echo "Le Deployment $D n'existe pas."; exit 1; }

REPLICAS=$(kubectl get deployment "$D" -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$REPLICAS" != "5" ]; then
  echo "Le Deployment $D a $REPLICAS réplica(s) : il en faut 5."
  exit 1
fi

AVAILABLE=$(kubectl get deployment "$D" -o jsonpath='{.status.availableReplicas}' 2>/dev/null)
if [ "$AVAILABLE" != "5" ]; then
  echo "Seulement ${AVAILABLE:-0} pod(s) sur 5 sont disponibles. Attends quelques secondes (k rollout status deploy $D)."
  exit 1
fi

# Un seul ReplicaSet : le scaling ne change pas le pod template
RS_COUNT=$(kubectl get rs -l app="$D" --no-headers 2>/dev/null | wc -l)
if [ "$RS_COUNT" -ne 1 ]; then
  echo "Il y a $RS_COUNT ReplicaSets pour $D : à cette étape, il ne devrait y en avoir qu'un (le pod template ne doit pas avoir changé)."
  exit 1
fi

# 3 pods au départ + 2 par le scaling + au moins 1 pour remplacer un pod supprimé = au moins 6 créations
CREATED=$(kubectl get events --field-selector involvedObject.kind=ReplicaSet,reason=SuccessfulCreate -o jsonpath='{range .items[*]}{.involvedObject.name}{"\n"}{end}' 2>/dev/null | grep -c "^${D}-")
if [ "$CREATED" -lt 6 ]; then
  echo "Aucun pod supprimé ne semble avoir été remplacé (créations observées : $CREATED, attendues : au moins 6)."
  echo "Supprime un pod avec k delete pod <nom>, puis vérifie qu'un nouveau pod apparaît."
  exit 1
fi

echo "$D est à 5 réplicas et le ReplicaSet a remplacé un pod supprimé."
exit 0
