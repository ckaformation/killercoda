#!/bin/bash
if ! kubectl wait --for=condition=Available deployment/greeting-operator -n operators --timeout=60s >/dev/null 2>&1; then
  echo "Le Deployment greeting-operator n'est pas encore Available dans le namespace operators."
  exit 1
fi

for NS in luke ben leia; do
  RESULT=$(kubectl auth can-i create configmaps --as=system:serviceaccount:operators:greeting-operator -n "$NS" 2>/dev/null)
  if [ "$RESULT" != "yes" ]; then
    echo "L'opérateur devrait pouvoir créer des configmaps dans $NS (obtenu: $RESULT)"
    exit 1
  fi
done

RESULT=$(kubectl auth can-i create configmaps --as=system:serviceaccount:operators:greeting-operator -n default 2>/dev/null)
if [ "$RESULT" = "yes" ]; then
  echo "L'opérateur ne devrait PAS pouvoir créer de configmaps dans default (le RBAC déborde de son périmètre)."
  exit 1
fi

echo "L'opérateur tourne et son RBAC est correctement scopé à luke, ben et leia."
exit 0
