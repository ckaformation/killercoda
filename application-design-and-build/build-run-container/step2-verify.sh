#!/bin/bash
ARCHIVE="/root/r2d2.tar"
IMAGE="localhost/r2d2:v1"

command -v podman >/dev/null 2>&1 || { echo "❌ La commande podman est introuvable."; exit 1; }

if [ ! -f "$ARCHIVE" ]; then
  echo "❌ L'archive $ARCHIVE est introuvable. Lance : podman save -o /root/r2d2.tar r2d2:v1"
  exit 1
fi

MANIFEST=$(tar -xOf "$ARCHIVE" manifest.json 2>/dev/null)
if ! echo "$MANIFEST" | grep -q "localhost/r2d2:v1"; then
  echo "❌ $ARCHIVE devrait être une archive de l'image r2d2:v1 (manifest.json absent ou sans le tag localhost/r2d2:v1)."
  exit 1
fi

IMG_ID=$(podman image inspect --format '{{.Id}}' "$IMAGE" 2>/dev/null)
if [ -z "$IMG_ID" ]; then
  echo "❌ L'image r2d2:v1 n'existe pas en local. Lance : podman load -i /root/r2d2.tar"
  exit 1
fi

if ! echo "$MANIFEST" | grep -q "$IMG_ID"; then
  echo "❌ L'image locale r2d2:v1 (ID ${IMG_ID:0:12}) n'est pas celle de l'archive $ARCHIVE."
  exit 1
fi

# Preuve par les evenements podman (s'ils sont disponibles) : dans l'ordre,
# un save, puis la suppression de r2d2:v1, puis un load
EVENTS=$(timeout 15 podman events --stream=false --since 3h --filter type=image --format '{{.Status}} {{.Name}}' 2>/dev/null)
if [ -n "$EVENTS" ]; then
  SEQ=$(echo "$EVENTS" | awk '
    $1=="save" {s=1}
    $1=="remove" && $2 ~ /r2d2:v1$/ && s {r=1}
    $1=="loadfromarchive" && r {l=1}
    END {print s+r+l}')
  if [ "$SEQ" != "3" ]; then
    echo "❌ Il faut, dans l'ordre : podman save, puis supprimer l'image (podman rm -f r2d2, puis podman rmi r2d2:v1), puis podman load -i /root/r2d2.tar."
    exit 1
  fi
fi

echo "✅ L'image r2d2:v1 a été exportée dans $ARCHIVE puis réimportée."
exit 0
