#!/bin/bash
D="x-wing"
DIR="/usr/share/nginx/html"

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

MAIN=$(containers_of containers)
NGINX=$(printf '%s\n' "$MAIN" | awk -F'|' '$2 ~ /^nginx(:|@|$)/' | head -n1)
if [ -z "$NGINX" ]; then
  echo "❌ Le Deployment $D devrait toujours avoir son container nginx (image nginx:alpine)."
  exit 1
fi

if printf '%s\n' "$MAIN" | awk -F'|' '$2 ~ /^busybox(:|@|$)/' | grep -q .; then
  echo "❌ busybox est déclaré dans containers : c'est un sidecar « classique ». Un sidecar natif se déclare dans initContainers, avec restartPolicy: Always."
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

SIDECAR=$(printf '%s\n' "$BUSY" | awk -F'|' '$3=="Always"' | head -n1)
if [ -z "$SIDECAR" ]; then
  RP=$(printf '%s\n' "$BUSY" | head -n1 | cut -d'|' -f3)
  echo "❌ L'initContainer busybox devrait porter restartPolicy: Always (obtenu : ${RP:-non défini}). Sans ce champ, c'est un init container classique : sa boucle ne se termine jamais et le pod reste en Init:0/1."
  exit 1
fi

SIDECAR_VOL=$(volume_at_dir "$SIDECAR")
if [ "$SIDECAR_VOL" != "$VOL" ]; then
  echo "❌ Le sidecar devrait monter le même volume que nginx ('$VOL') sous $DIR (obtenu : '${SIDECAR_VOL:-aucun volume sur ce chemin}')."
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

# 3 lectures espacees de 2 s : au moins 2 nombres differents attendus
VALUES=""
for i in 1 2 3; do
  V=$(curl -s --max-time 3 "http://$IP/" 2>/dev/null | tr -d '[:space:]')
  case "$V" in
    ''|*[!0-9]*) ;;
    *) VALUES="$VALUES $V" ;;
  esac
  [ "$i" -lt 3 ] && sleep 2
done

DISTINCT=$(printf '%s\n' $VALUES | grep . | sort -u | wc -l)
if [ "$DISTINCT" -lt 2 ]; then
  echo "❌ nginx devrait renvoyer un nombre qui change chaque seconde (obtenu :${VALUES:- aucun nombre}). Vérifie la commande du sidecar et relance la vérification."
  exit 1
fi

echo "✅ Le sidecar natif réécrit la page dans le volume emptyDir '$VOL' pendant que nginx la sert (lu :$VALUES)."
exit 0
