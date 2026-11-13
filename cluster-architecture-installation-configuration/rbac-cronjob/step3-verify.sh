#!/bin/bash
RESULT=$(kubectl auth can-i delete pods --as=system:serviceaccount:ops:leon-2 -n ops 2>/dev/null)
if [ "$RESULT" != "yes" ]; then
  echo "leon-2 devrait pouvoir delete pods dans ops (obtenu: $RESULT)"
  exit 1
fi
echo "leon-2 dispose bien des droits delete sur les pods dans ops."
exit 0
