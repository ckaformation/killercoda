#!/bin/bash
S="lightsaber"
URL="http://jedi-temple:30080"

kubectl get svc "$S" >/dev/null 2>&1 || { echo "❌ Le Service $S est introuvable."; exit 1; }

TYPE=$(kubectl get svc "$S" -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$TYPE" != "NodePort" ]; then
  echo "❌ Le Service $S doit rester de type NodePort (obtenu : '$TYPE')."
  exit 1
fi

NODEPORT=$(kubectl get svc "$S" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ "$NODEPORT" != "30080" ]; then
  echo "❌ Le nodePort du Service $S doit rester 30080 (obtenu : '$NODEPORT')."
  exit 1
fi

APP=$(kubectl get svc "$S" -o jsonpath='{.spec.selector.app}' 2>/dev/null)
VERSION=$(kubectl get svc "$S" -o jsonpath='{.spec.selector.version}' 2>/dev/null)
if [ "$APP" != "lightsaber" ]; then
  echo "❌ Le selector du Service doit garder app=lightsaber (obtenu : app='$APP')."
  exit 1
fi
if [ "$VERSION" != "green" ]; then
  echo "❌ Le selector du Service doit cibler version=green (obtenu : version='$VERSION')."
  exit 1
fi

# En blue/green, les deux versions doivent continuer de tourner.
for D in lightsaber-blue lightsaber-green; do
  READY=$(kubectl get deployment "$D" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "${READY:-0}" != "2" ]; then
    echo "❌ Le Deployment $D doit avoir 2 pods prêts (obtenu : '${READY:-0}'). Les deux versions doivent rester en place."
    exit 1
  fi
done

for i in $(seq 1 6); do
  R=$(curl -s --max-time 5 "$URL")
  if ! echo "$R" | grep -q "version green"; then
    echo "❌ $URL devrait répondre 'version green' à chaque appel (obtenu : '${R:-aucune réponse}'). Si tu viens de modifier le Service, attends quelques secondes et relance la vérification."
    exit 1
  fi
done

echo "✅ Le Service $S envoie tout le trafic vers green, et blue est toujours prêt pour un retour arrière."
exit 0
