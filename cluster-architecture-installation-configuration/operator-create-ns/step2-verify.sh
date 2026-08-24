#!/bin/bash
if ! kubectl get crd namespacesets.training.example.com >/dev/null 2>&1; then
  echo "La CRD namespacesets.training.example.com n'existe pas encore."
  exit 1
fi

ESTABLISHED=$(kubectl get crd namespacesets.training.example.com -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' 2>/dev/null)
if [ "$ESTABLISHED" != "True" ]; then
  echo "La CRD n'est pas encore Established (obtenu: '$ESTABLISHED')."
  exit 1
fi

echo "La CRD namespacesets.training.example.com est bien enregistrée."
exit 0
