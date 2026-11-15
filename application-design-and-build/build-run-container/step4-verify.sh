#!/bin/bash
POD="r2d2"
EXPECTED_IMAGE="localhost:5000/r2d2:v1"

if ! kubectl get pod "$POD" >/dev/null 2>&1; then
  echo "❌ Le pod $POD est introuvable dans le namespace default. Lance : k run r2d2 --image=localhost:5000/r2d2:v1"
  exit 1
fi

IMAGE=$(kubectl get pod "$POD" -o jsonpath='{.spec.containers[0].image}' 2>/dev/null)
if [ "$IMAGE" != "$EXPECTED_IMAGE" ]; then
  echo "❌ Le pod $POD devrait utiliser l'image $EXPECTED_IMAGE (obtenu : '$IMAGE'). Supprime-le (k delete pod r2d2 --force) et recrée-le."
  exit 1
fi

if ! kubectl wait --for=condition=Ready "pod/$POD" --timeout=60s >/dev/null 2>&1; then
  REASON=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null)
  echo "❌ Le pod $POD n'est pas Ready (raison : '${REASON:-inconnue}'). Regarde k describe pod r2d2, puis relance la vérification."
  exit 1
fi

if ! kubectl logs "$POD" --tail=20 2>/dev/null | grep -q "bytes from 127\.0\.0\.1"; then
  echo "❌ Les logs du pod $POD ne montrent pas encore de réponse de 127.0.0.1. Attends quelques secondes et relance la vérification."
  exit 1
fi

echo "✅ Le pod $POD tourne avec l'image de la registry locale et ping 127.0.0.1."
exit 0
