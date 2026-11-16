#!/bin/bash
URL="http://yavin:30080"

fail() { echo "❌ $1"; exit 1; }

# $1 = Deployment, $2 = nombre de replicas attendu (tous prets)
check_deploy() {
  kubectl get deployment "$1" >/dev/null 2>&1 || fail "Le Deployment $1 est introuvable."
  SPEC=$(kubectl get deployment "$1" -o jsonpath='{.spec.replicas}' 2>/dev/null)
  [ "$SPEC" = "$2" ] || fail "Le Deployment $1 doit avoir $2 réplica(s) (obtenu : '$SPEC')."
  kubectl rollout status deployment/"$1" --timeout=90s >/dev/null 2>&1 || fail "Le rollout de $1 n'est pas terminé. Lance : kubectl rollout status deployment/$1"
  READY=$(kubectl get deployment "$1" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  [ "${READY:-0}" = "$2" ] || fail "Le Deployment $1 doit avoir $2 pod(s) prêt(s) (obtenu : '${READY:-0}')."
}

# Le Service doit viser les deux versions (app=x-wing, sans track).
TYPE=$(kubectl get svc x-wing -o jsonpath='{.spec.type}' 2>/dev/null)
NODEPORT=$(kubectl get svc x-wing -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
[ "$TYPE" = "NodePort" ] && [ "$NODEPORT" = "30080" ] || fail "Le Service x-wing doit rester de type NodePort sur le port 30080 (obtenu : type '$TYPE', nodePort '$NODEPORT')."
SEL_APP=$(kubectl get svc x-wing -o jsonpath='{.spec.selector.app}' 2>/dev/null)
SEL_TRACK=$(kubectl get svc x-wing -o jsonpath='{.spec.selector.track}' 2>/dev/null)
[ "$SEL_APP" = "x-wing" ] && [ -z "$SEL_TRACK" ] || fail "Le selector du Service x-wing doit rester app=x-wing, sans track (obtenu : app='$SEL_APP', track='$SEL_TRACK')."

# Definition de la version canary
kubectl get deployment x-wing-canary >/dev/null 2>&1 || fail "Le Deployment x-wing-canary est introuvable. Lance : kubectl apply -f /root/x-wing-canary.yaml"
for F in '{.spec.selector.matchLabels.track}' '{.spec.template.metadata.labels.track}'; do
  V=$(kubectl get deployment x-wing-canary -o jsonpath="$F" 2>/dev/null)
  [ "$V" = "canary" ] || fail "x-wing-canary doit porter track=canary dans son selector et dans son template (obtenu : '$V')."
done
for F in '{.spec.selector.matchLabels.app}' '{.spec.template.metadata.labels.app}'; do
  V=$(kubectl get deployment x-wing-canary -o jsonpath="$F" 2>/dev/null)
  [ "$V" = "x-wing" ] || fail "x-wing-canary doit garder app=x-wing dans son selector et dans son template (obtenu : '$V')."
done
CM=$(kubectl get deployment x-wing-canary -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}' 2>/dev/null)
[ "$CM" = "x-wing-canary-page" ] || fail "x-wing-canary doit monter la ConfigMap x-wing-canary-page (obtenu : '$CM')."

# Replicas : 0 current (Deployment conserve pour un retour arriere) + 4 canary
check_deploy x-wing-current 0
check_deploy x-wing-canary 4

# Repartition reelle du trafic
curl -s --max-time 5 "$URL" | grep -q "version : " || fail "$URL ne répond pas."
CANARY=0; CURRENT=0
for i in $(seq 1 100); do
  R=$(curl -s --max-time 3 "$URL")
  case "$R" in
    *"version : Canary"*) CANARY=$((CANARY + 1)) ;;
    *"version : Current"*) CURRENT=$((CURRENT + 1)) ;;
  esac
done
[ $((CANARY + CURRENT)) -eq 100 ] || fail "Seules $((CANARY + CURRENT)) requêtes sur 100 ont reçu une réponse valide. Relance la vérification."
if [ "$CANARY" -ne 100 ]; then
  fail "Sur 100 requêtes : $CANARY canary et $CURRENT current, attendu 100 canary. Si des pods current sont encore en cours d'arrêt, attends quelques secondes et relance la vérification."
fi

echo "✅ 4 pods canary et x-wing-current à 0 réplica : les 100 requêtes sont arrivées sur la canary."
exit 0
