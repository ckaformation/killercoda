#!/bin/bash
D="snowspeeder"

kubectl get deployment "$D" >/dev/null 2>&1 || { echo "Le Deployment $D n'existe pas."; exit 1; }

IMAGE=$(kubectl get deployment "$D" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$IMAGE" = "nginx:alpine" ]; then
  echo "L'image du Deployment $D est toujours nginx:alpine : mets-la à jour avec k set image."
  exit 1
fi

if ! kubectl rollout status deployment/"$D" --timeout=90s >/dev/null 2>&1; then
  echo "Le déploiement de la nouvelle image n'est pas terminé. Lance : k rollout status deploy $D"
  exit 1
fi

for FIELD in replicas updatedReplicas availableReplicas; do
  VALUE=$(kubectl get deployment "$D" -o jsonpath="{.status.$FIELD}" 2>/dev/null)
  if [ "$VALUE" != "5" ]; then
    echo "status.$FIELD vaut '${VALUE:-0}' au lieu de 5 : le Deployment doit toujours avoir 5 réplicas, tous mis à jour."
    exit 1
  fi
done

# Deux ReplicaSets : l'ancien (nginx:alpine) à 0 réplica, le nouveau à 5
RS_LINES=$(kubectl get rs -l app="$D" -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].image}{" "}{.spec.replicas}{"\n"}{end}' 2>/dev/null)

RS_COUNT=$(echo "$RS_LINES" | grep -c .)
if [ "$RS_COUNT" -lt 2 ]; then
  echo "Il n'y a qu'un seul ReplicaSet : la mise à jour de l'image aurait dû en créer un second."
  exit 1
fi

if ! echo "$RS_LINES" | grep -qx "nginx:alpine 0"; then
  echo "L'ancien ReplicaSet (nginx:alpine) devrait être à 0 réplica. Relance k get rs -o wide."
  exit 1
fi

if ! echo "$RS_LINES" | grep -qx "$IMAGE 5"; then
  echo "Aucun ReplicaSet utilisant l'image $IMAGE n'est à 5 réplicas."
  exit 1
fi

echo "$D utilise maintenant l'image $IMAGE : un nouveau ReplicaSet porte les 5 pods et l'ancien est à 0."
exit 0
