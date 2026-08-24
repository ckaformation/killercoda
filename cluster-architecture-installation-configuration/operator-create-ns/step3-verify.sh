#!/bin/bash
if ! kubectl get namespaceset my-teams >/dev/null 2>&1; then
  echo "La ressource NamespaceSet/my-teams n'existe pas encore."
  exit 1
fi

TIMEOUT=40
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  MISSING=0
  for ns in team-red team-green team-blue; do
    kubectl get namespace "$ns" >/dev/null 2>&1 || MISSING=$((MISSING + 1))
  done
  [ "$MISSING" -eq 0 ] && break
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

if [ "$MISSING" -ne 0 ]; then
  echo "Il manque encore $MISSING des 3 namespaces attendus (team-red, team-green, team-blue)."
  exit 1
fi

echo "Les 3 namespaces ont bien été créés par l'opérateur."
exit 0
