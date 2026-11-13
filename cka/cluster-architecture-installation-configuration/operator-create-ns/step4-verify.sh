#!/bin/bash
RESULT=$(kubectl auth can-i patch namespaces --as=system:serviceaccount:operators:namespace-operator 2>/dev/null)
if [ "$RESULT" != "yes" ]; then
  echo "Le ClusterRole namespace-operator-role devrait autoriser le verbe patch sur namespaces (obtenu: $RESULT)"
  exit 1
fi

TIMEOUT=40
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  MISSING=0
  for ns in rogue-1 rogue-2 rogue-3; do
    LABEL=$(kubectl get namespace "$ns" -o jsonpath='{.metadata.labels.managed-by}' 2>/dev/null)
    [ "$LABEL" = "namespace-operator" ] || MISSING=$((MISSING + 1))
  done
  [ "$MISSING" -eq 0 ] && break
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

if [ "$MISSING" -ne 0 ]; then
  echo "Il manque encore le label managed-by=namespace-operator sur $MISSING des 3 namespaces."
  exit 1
fi

echo "Le ClusterRole autorise patch, et les 3 namespaces sont bien labellisés par l'opérateur."
exit 0
