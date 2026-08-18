#!/bin/bash
OK=true
NS=jedi

for VERB in create delete; do
  for RES in pods deployments statefulsets; do
    RESULT=$(kubectl auth can-i "$VERB" "$RES" --as=luke -n "$NS" 2>/dev/null)
    if [ "$RESULT" != "yes" ]; then
      echo "luke devrait pouvoir '$VERB' '$RES' dans le namespace $NS (obtenu: $RESULT)"
      OK=false
    fi
  done
done

for VERB in create delete; do
  for RES in pods deployments statefulsets; do
    RESULT=$(kubectl auth can-i "$VERB" "$RES" --as=luke -n default 2>/dev/null)
    if [ "$RESULT" = "yes" ]; then
      echo "luke ne devrait PAS pouvoir '$VERB' '$RES' dans le namespace default (la permission déborde hors de $NS)"
      OK=false
    fi
  done
done

if [ "$OK" = "true" ]; then
  echo "Permissions de luke correctement scopées sur le namespace jedi."
  exit 0
fi
exit 1
