#!/bin/bash
NS="jedi-archives"
PVC="holocron-storage"

if [ ! -f /root/.prep-done ]; then
  echo "❌ L'environnement n'est pas encore prêt"
  exit 1
fi

STATUS=$(kubectl get pvc "$PVC" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$STATUS" != "Bound" ]; then
  echo "❌ Le PVC $PVC n'est pas Bound (statut: $STATUS)"
  exit 1
fi
echo "✅ PVC $PVC Bound"

PV_NAME=$(kubectl get pvc "$PVC" -n "$NS" -o jsonpath='{.spec.volumeName}')
if [ -z "$PV_NAME" ]; then
  echo "❌ Impossible de déterminer le PV lié au PVC"
  exit 1
fi

MODES=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.accessModes[*]}')
if ! echo " $MODES " | grep -q ' ReadWriteOnce '; then
  echo "❌ Le PV lié ($PV_NAME) ne supporte pas ReadWriteOnce (modes actuels: $MODES)"
  echo "As-tu corrigé le PV, ou seulement modifié le PVC pour contourner le problème ?"
  exit 1
fi
echo "✅ Le PV lié supporte ReadWriteOnce"

exit 0
