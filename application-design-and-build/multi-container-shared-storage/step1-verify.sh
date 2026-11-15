#!/bin/bash
D="dagobah"
DIR="/usr/share/nginx/html"
EXPECTED="Hello from init"

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

EMPTYDIR=$(volumes_of | awk -F'|' -v v="$VOL" '$1==v {print $2; exit}')
if [ -z "$EMPTYDIR" ]; then
  echo "❌ Le volume '$VOL' monté par nginx sous $DIR devrait être de type emptyDir."
  exit 1
fi

INITS=$(containers_of initContainers)
BUSY=$(printf '%s\n' "$INITS" | awk -F'|' '$2 ~ /^busybox(:|@|$)/')
if [ -z "$BUSY" ]; then
  IMAGES=$(printf '%s\n' "$INITS" | cut -d'|' -f2 | grep . | paste -sd, -)
  echo "❌ Le Deployment $D devrait avoir un initContainer avec l'image busybox (obtenu : ${IMAGES:-aucun initContainer})."
  exit 1
fi

INIT=$(printf '%s\n' "$BUSY" | awk -F'|' '$3!="Always"' | head -n1)
if [ -z "$INIT" ]; then
  echo "❌ L'initContainer busybox porte restartPolicy: Always, ce qui en fait un sidecar. À cette étape, on veut un init container classique, sans restartPolicy."
  exit 1
fi

INIT_VOL=$(volume_at_dir "$INIT")
if [ "$INIT_VOL" != "$VOL" ]; then
  echo "❌ L'init container devrait monter le même volume que nginx ('$VOL') sous $DIR (obtenu : '${INIT_VOL:-aucun volume sur ce chemin}')."
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
  echo "❌ nginx devrait renvoyer « $EXPECTED » (obtenu : '$(printf '%s' "$PAGE" | tr -d '\n' | head -c 80)')."
  exit 1
fi

echo "✅ L'init container a écrit la page dans le volume emptyDir '$VOL', et nginx la sert."
exit 0
