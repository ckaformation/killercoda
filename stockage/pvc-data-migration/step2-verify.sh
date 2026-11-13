#!/bin/bash
NS="hoth"
OLD_PVC="echo-base-data"

JOB_NAME=""
for j in $(kubectl get job -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  IMG=$(kubectl get job "$j" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
  if [ "$IMG" = "bash:5" ]; then
    JOB_NAME="$j"
    break
  fi
done

if [ -z "$JOB_NAME" ]; then
  echo "❌ Aucun Job utilisant l'image bash:5 trouvé dans $NS"
  exit 1
fi
echo "✅ Job trouvé : $JOB_NAME"

SUCCEEDED=$(kubectl get job "$JOB_NAME" -n "$NS" -o jsonpath='{.status.succeeded}')
if [ "$SUCCEEDED" != "1" ]; then
  echo "❌ Le Job $JOB_NAME ne s'est pas terminé avec succès (succeeded: '$SUCCEEDED')"
  exit 1
fi
echo "✅ Job terminé avec succès"

NEW_PVC=$(kubectl get job "$JOB_NAME" -n "$NS" -o jsonpath='{range .spec.template.spec.volumes[*]}{.persistentVolumeClaim.claimName}{"\n"}{end}' | grep -v "^${OLD_PVC}$" | grep -v '^$' | head -n1)
if [ -z "$NEW_PVC" ]; then
  echo "❌ Impossible de déterminer le nouveau PVC monté par le Job"
  exit 1
fi
echo "✅ Nouveau PVC utilisé par le Job : $NEW_PVC"

check_file_present() {
  local pvc="$1"
  local pv
  pv=$(kubectl get pvc "$pvc" -n "$NS" -o jsonpath='{.spec.volumeName}' 2>/dev/null)
  local hostpath
  hostpath=$(kubectl get pv "$pv" -o jsonpath='{.spec.hostPath.path}' 2>/dev/null)
  if [ -n "$hostpath" ] && [ -f "${hostpath}/rebel-plans.txt" ]; then
    return 0
  fi
  if find /opt/local-path-provisioner -name rebel-plans.txt 2>/dev/null | grep -q rebel-plans.txt; then
    return 0
  fi
  return 1
}

if ! check_file_present "$OLD_PVC"; then
  echo "❌ rebel-plans.txt introuvable sur le disque pour l'ancien PVC ($OLD_PVC)"
  exit 1
fi
echo "✅ Données présentes dans l'ancien PVC"

if ! check_file_present "$NEW_PVC"; then
  echo "❌ rebel-plans.txt introuvable sur le disque pour le nouveau PVC ($NEW_PVC)"
  exit 1
fi
echo "✅ Données présentes dans le nouveau PVC"

exit 0
