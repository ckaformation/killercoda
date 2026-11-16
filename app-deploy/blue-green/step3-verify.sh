#!/bin/bash
S="lightsaber-green"
PUBLIC="lightsaber"
URL="http://jedi-temple:30080"

kubectl get svc "$S" >/dev/null 2>&1 || { echo "❌ Le Service $S est introuvable. Crée-le avec : kubectl expose deployment lightsaber-green --port=80"; exit 1; }

TYPE=$(kubectl get svc "$S" -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$TYPE" != "ClusterIP" ]; then
  echo "❌ Le Service $S doit être de type ClusterIP (obtenu : '$TYPE')."
  exit 1
fi

PORT=$(kubectl get svc "$S" -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)
if [ "$PORT" != "80" ]; then
  echo "❌ Le Service $S doit écouter sur le port 80 (obtenu : '$PORT')."
  exit 1
fi

APP=$(kubectl get svc "$S" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
VERSION=$(kubectl get svc "$S" -o jsonpath='{.spec.selector.version}' 2>/dev/null)
if [ "$APP" != "lightsaber" ] || [ "$VERSION" != "green" ]; then
  echo "❌ Le selector de $S doit être app=lightsaber,version=green (obtenu : app='$APP', version='$VERSION')."
  exit 1
fi

# Test fonctionnel depuis l'interieur du cluster (DNS + ClusterIP),
# a partir d'un pod existant (wget est fourni par busybox dans nginx:alpine).
R=$(kubectl exec deploy/lightsaber-blue -- wget -qO- -T 5 "http://$S" 2>/dev/null)
if ! echo "$R" | grep -q "version green"; then
  echo "❌ Depuis un pod du cluster, http://$S devrait répondre 'version green' (obtenu : '${R:-aucune réponse}')."
  exit 1
fi

# Le trafic public doit rester sur blue.
PUBLIC_VERSION=$(kubectl get svc "$PUBLIC" -o jsonpath='{.spec.selector.version}' 2>/dev/null)
if [ "$PUBLIC_VERSION" != "blue" ]; then
  echo "❌ Le Service $PUBLIC doit continuer de cibler version=blue (obtenu : version='$PUBLIC_VERSION')."
  exit 1
fi
for i in $(seq 1 3); do
  R=$(curl -s --max-time 5 "$URL")
  if ! echo "$R" | grep -q "version blue"; then
    echo "❌ $URL devrait toujours répondre 'version blue' (obtenu : '${R:-aucune réponse}')."
    exit 1
  fi
done

echo "✅ green est joignable en interne via le Service ClusterIP $S, et le trafic public reste sur blue."
exit 0
