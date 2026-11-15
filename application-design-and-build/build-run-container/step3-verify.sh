#!/bin/bash
REG="http://localhost:5000"
IMAGE="localhost/r2d2:v1"

command -v podman >/dev/null 2>&1 || { echo "❌ La commande podman est introuvable."; exit 1; }

if ! curl -s --max-time 5 "$REG/v2/" >/dev/null 2>&1; then
  echo "❌ La registry ne répond pas sur localhost:5000 (podman ps : le container jedi-archives doit être Up)."
  exit 1
fi

if ! podman image inspect localhost:5000/r2d2:v1 >/dev/null 2>&1; then
  echo "❌ Le nom localhost:5000/r2d2:v1 n'existe pas en local. Lance : podman tag r2d2:v1 localhost:5000/r2d2:v1"
  exit 1
fi

TAGS=$(curl -s --max-time 5 "$REG/v2/r2d2/tags/list")
if ! echo "$TAGS" | grep -q '"v1"'; then
  echo "❌ La registry devrait contenir r2d2:v1 (obtenu : '$TAGS'). Lance : podman push localhost:5000/r2d2:v1"
  exit 1
fi

# L'image de la registry doit etre celle construite a l'etape 1 :
# l'ID d'une image podman est le digest de sa configuration.
IMG_ID=$(podman image inspect --format '{{.Id}}' "$IMAGE" 2>/dev/null)
MANIFEST=$(curl -s --max-time 5 \
  -H "Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json" \
  "$REG/v2/r2d2/manifests/v1")
if [ -z "$IMG_ID" ] || ! echo "$MANIFEST" | grep -q "sha256:$IMG_ID"; then
  echo "❌ L'image r2d2:v1 de la registry n'est pas celle de ton image locale r2d2:v1. Tagge et pousse de nouveau."
  exit 1
fi

echo "✅ L'image r2d2:v1 est dans la registry localhost:5000."
exit 0
