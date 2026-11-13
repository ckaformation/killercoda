#!/bin/bash
for VERB in get list delete; do
  RESULT=$(kubectl auth can-i "$VERB" pods --as=system:serviceaccount:ops:leon -n ops 2>/dev/null)
  if [ "$RESULT" != "yes" ]; then
    echo "leon devrait pouvoir '$VERB' pods dans ops (obtenu: $RESULT)"
    exit 1
  fi
done
echo "leon dispose des droits nécessaires sur les pods dans ops."

TIMEOUT=90
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  REMAINING=0
  for i in 1 2 3; do
    kubectl get "pod/pod-a-nettoyer-$i" -n ops >/dev/null 2>&1 && REMAINING=$((REMAINING + 1))
  done
  [ "$REMAINING" -eq 0 ] && break
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

if [ "$REMAINING" -ne 0 ]; then
  echo "Les pods pod-a-nettoyer-* ne sont pas encore supprimés (le CronJob n'a peut-être pas encore eu son prochain déclenchement planifié)."
  exit 1
fi

echo "Le CronJob a bien supprimé les pods Completed automatiquement."
exit 0
