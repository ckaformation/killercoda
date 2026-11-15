#!/bin/bash
D="jedi-archives"
DIR="/usr/share/nginx/html"
PVC="holocron"
PV="holocron-pv"
EXPECTED="Archives Jedi"

# Une ligne par container : nom|image|restartPolicy|volume=chemin,volume=chemin,
containers_of() {
  kubectl get deploy "$D" -o jsonpath='{range .spec.template.spec.'"$1"'[*]}{.name}{"|"}{.image}{"|"}{.restartPolicy}{"|"}{range .volumeMounts[*]}{.name}{"="}{.mountPath}{","}{end}{"\n"}{end}' 2>/dev/null
}
# Une ligne par volume : nom|emptyDir|claimName
volumes_of() {
  kubectl get deploy "$D" -o jsonpath='{range .spec.template.spec.volumes[*]}{.name}{"|"}{.emptyDir}{"|"}{.persistentVolumeClaim.claimName}{"\n"}{end}' 2>/dev/null
}
# Nom du volume monte sous $DIR, a partir d'une ligne de containers_of
volume_at_dir() {
  printf '%s\n' "$1" | cut -d'|' -f4 | tr ',' '\n' | sed 's#/*$##' | awk -F'=' -v d="$DIR" '$2==d {print $1; exit}'
}
# IP d'un pod Ready du Deployment, hors pods en cours de suppression
ready_pod_ip() {
  kubectl get pods -l "app=$D" -o jsonpath='{range .items[*]}{.metadata.deletionTimestamp}{"|"}{.status.conditions[?(@.type=="Ready")].status}{"|"}{.status.podIP}{"\n"}{end}' 2>/dev/null | awk -F'|' '$1=="" && $2=="True" && $3!="" {print $3; exit}'
}

kubectl get deploy "$D" >/dev/null 2>&1 || {
  echo "❌ Le Deployment $D est introuvable dans le namespace default."
  exit 1
}

NGINX=$(containers_of containers | awk -F'|' '$2 ~ /^nginx(:|@|$)/' | head -n1)
if [ -z "$NGINX" ]; then
  echo "❌ Le Deployment $D devrait toujours avoir son container nginx (image nginx:alpine)."
  exit 1
fi

VOL=$(volume_at_dir "$NGINX")
if [ -z "$VOL" ]; then
  echo "❌ Le container nginx devrait monter un volume sous $DIR (obtenu : aucun volumeMount sur ce chemin). As-tu bien fait k apply -f /root/$D.yaml ?"
  exit 1
fi

CLAIM=$(volumes_of | awk -F'|' -v v="$VOL" '$1==v {print $3; exit}')
if [ "$CLAIM" != "$PVC" ]; then
  echo "❌ Le volume '$VOL' monté par nginx sous $DIR devrait utiliser le PVC $PVC (obtenu : '${CLAIM:-pas un PVC}')."
  exit 1
fi

PHASE=$(kubectl get pvc "$PVC" -o jsonpath='{.status.phase}' 2>/dev/null)
BOUND_PV=$(kubectl get pvc "$PVC" -o jsonpath='{.spec.volumeName}' 2>/dev/null)
if [ "$PHASE" != "Bound" ] || [ "$BOUND_PV" != "$PV" ]; then
  echo "❌ Le PVC $PVC devrait rester Bound au PV $PV (obtenu : statut '${PHASE:-PVC introuvable}', PV '${BOUND_PV:-aucun}'). Il n'y avait pas à le modifier."
  exit 1
fi

if ! kubectl rollout status deploy "$D" --timeout=90s >/dev/null 2>&1; then
  echo "❌ Le Deployment $D n'est pas disponible. Regarde k get pods -l app=$D et k describe pod -l app=$D, puis relance la vérification."
  exit 1
fi

IP=""
for i in $(seq 1 15); do
  IP=$(ready_pod_ip)
  [ -n "$IP" ] && break
  sleep 2
done
if [ -z "$IP" ]; then
  echo "❌ Aucun pod Ready pour $D (k get pods -l app=$D). Attends quelques secondes et relance la vérification."
  exit 1
fi

PAGE=$(curl -s --max-time 5 "http://$IP/" 2>/dev/null)
if ! printf '%s' "$PAGE" | grep -qF "$EXPECTED"; then
  echo "❌ nginx devrait renvoyer la page « $EXPECTED » stockée sur le PVC (obtenu : '$(printf '%s' "$PAGE" | tr -d '\n' | head -c 80)')."
  exit 1
fi

echo "✅ nginx sert la page stockée sur le PVC $PVC, monté sous $DIR."
exit 0
