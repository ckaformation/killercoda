#!/bin/bash
NS="jedi-archives"
PVC="holocron-storage"

DEPLOY_NAME=""
for d in $(kubectl get deploy -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
  IMG=$(kubectl get deploy "$d" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
  if [ "$IMG" = "postgres:16-alpine" ]; then
    DEPLOY_NAME="$d"
    break
  fi
done

if [ -z "$DEPLOY_NAME" ]; then
  echo "❌ Aucun Deployment utilisant l'image postgres:16-alpine trouvé dans $NS"
  exit 1
fi
echo "✅ Deployment trouvé : $DEPLOY_NAME"

PASSWORD=$(kubectl get deploy "$DEPLOY_NAME" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="POSTGRES_PASSWORD")].value}' 2>/dev/null)
if [ "$PASSWORD" != "secret" ]; then
  echo "❌ POSTGRES_PASSWORD attendu 'secret', trouvé '$PASSWORD'"
  exit 1
fi
echo "✅ POSTGRES_PASSWORD correct"

MOUNT_PATH=$(kubectl get deploy "$DEPLOY_NAME" -n "$NS" -o jsonpath="{.spec.template.spec.containers[0].volumeMounts[?(@.name=='data')].mountPath}" 2>/dev/null)
if [ -z "$MOUNT_PATH" ]; then
  MOUNT_PATH=$(kubectl get deploy "$DEPLOY_NAME" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null)
fi
if [ "$MOUNT_PATH" != "/var/lib/postgresql/data" ]; then
  echo "❌ Le volume doit être monté sur /var/lib/postgresql/data (trouvé: '$MOUNT_PATH')"
  exit 1
fi
echo "✅ Monté sur /var/lib/postgresql/data"

CLAIM=$(kubectl get deploy "$DEPLOY_NAME" -n "$NS" -o jsonpath="{.spec.template.spec.volumes[?(@.persistentVolumeClaim.claimName=='$PVC')].persistentVolumeClaim.claimName}" 2>/dev/null)
if [ "$CLAIM" != "$PVC" ]; then
  echo "❌ Le Deployment doit utiliser le PVC $PVC (trouvé: '$CLAIM')"
  exit 1
fi
echo "✅ PVC $PVC bien référencé"

echo "Attente de la stabilisation du Deployment..."
if ! kubectl -n "$NS" rollout status deployment/"$DEPLOY_NAME" --timeout=90s; then
  echo "❌ Le pod PostgreSQL n'est pas Running/Ready"
  exit 1
fi
echo "✅ Pod PostgreSQL Running/Ready"

exit 0
