#!/bin/bash
if ! kubectl get deployment x-wing-fleet >/dev/null 2>&1; then
  echo "Le Deployment x-wing-fleet n'existe pas encore."
  exit 1
fi

REPLICAS=$(kubectl get deployment x-wing-fleet -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$REPLICAS" != "3" ]; then
  echo "Le Deployment x-wing-fleet devrait avoir 3 replicas (obtenu: $REPLICAS)."
  exit 1
fi

if ! kubectl wait --for=condition=Available deployment/x-wing-fleet --timeout=60s >/dev/null 2>&1; then
  echo "Le Deployment x-wing-fleet n'est pas encore Available."
  exit 1
fi

RS_COUNT=$(kubectl get replicaset -l app=x-wing-fleet --no-headers 2>/dev/null | wc -l)
if [ "$RS_COUNT" -ne 1 ]; then
  echo "Il ne devrait y avoir qu'un seul ReplicaSet à ce stade (trouvés: $RS_COUNT) : le scaling seul ne doit pas créer de nouvelle révision."
  exit 1
fi

echo "x-wing-fleet est scalé à 3 replicas, toujours sur une seule révision."
exit 0
