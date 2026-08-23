#!/bin/bash
for VERB in get list delete; do
  RESULT=$(kubectl auth can-i "$VERB" pods --as=system:serviceaccount:ops:leon -n ops 2>/dev/null)
  if [ "$RESULT" != "yes" ]; then
    echo "leon devrait pouvoir '$VERB' pods dans ops (obtenu: $RESULT)"
    exit 1
  fi
done
echo "leon dispose des droits nécessaires sur les pods dans ops."
exit 0
