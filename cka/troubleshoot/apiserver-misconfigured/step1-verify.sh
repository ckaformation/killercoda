#!/bin/bash
MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

if grep -q "metadata;" "$MANIFEST" 2>/dev/null; then
  echo "❌ 'metadata;' toujours présent dans le manifest (erreur 1 non corrigée)"
  exit 1
fi
echo "✅ Erreur 1 corrigée (metadata: valide)"

if grep -q "midichlorians" "$MANIFEST" 2>/dev/null; then
  echo "❌ L'argument --midichlorians est toujours présent (erreur 2 non corrigée)"
  exit 1
fi
echo "✅ Erreur 2 corrigée (argument inconnu retiré)"

if grep -q "apiserver-WRONG.crt" "$MANIFEST" 2>/dev/null; then
  echo "❌ --tls-cert-file pointe encore vers le chemin erroné (erreur 3 non corrigée)"
  exit 1
fi
echo "✅ Erreur 3 corrigée (chemin du certificat rétabli)"

CONTAINER_ID=""
for i in $(seq 1 10); do
  CONTAINER_ID=$(crictl ps --name kube-apiserver -q 2>/dev/null | head -n1)
  if [ -n "$CONTAINER_ID" ]; then
    break
  fi
  sleep 3
done

if [ -z "$CONTAINER_ID" ]; then
  echo "❌ Aucun conteneur kube-apiserver en cours d'exécution"
  exit 1
fi
echo "✅ Conteneur kube-apiserver en cours d'exécution ($CONTAINER_ID)"

exit 0
