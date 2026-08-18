#!/bin/bash
OK=true

for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
  RESULT=$(kubectl auth can-i get pods --as=luke -n "$ns" 2>/dev/null)
  case "$ns" in
    kube-*)
      if [ "$RESULT" = "yes" ]; then
        echo "luke ne devrait PAS avoir la permission view dans $ns (namespace kube-*)"
        OK=false
      fi
      ;;
    *)
      if [ "$RESULT" != "yes" ]; then
        echo "luke devrait avoir la permission view dans $ns (obtenu: $RESULT)"
        OK=false
      fi
      ;;
  esac
done

if [ "$OK" = "true" ]; then
  echo "Permissions view correctement appliquées : tous les namespaces sauf kube-*."
  exit 0
fi
exit 1
