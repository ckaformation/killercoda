#!/bin/bash
EXCLUDE="kube-system kube-public kube-node-lease default death-star"

CANDIDATE_NS=""
DEPLOY_NAME=""
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  case " $EXCLUDE " in *" $ns "*) continue;; esac
  for d in $(kubectl get deploy -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    IMAGES=$(kubectl get deploy "$d" -n "$ns" -o jsonpath='{.spec.template.spec.containers[*].image}')
    if echo " $IMAGES " | grep -q ' nginx:1-alpine '; then
      CANDIDATE_NS="$ns"
      DEPLOY_NAME="$d"
      break 2
    fi
  done
done

if [ -z "$CANDIDATE_NS" ]; then
  echo "❌ Aucun Deployment basé sur nginx:1-alpine trouvé dans un nouveau namespace"
  exit 1
fi
echo "✅ Deployment trouvé : $DEPLOY_NAME (namespace $CANDIDATE_NS)"

READY=$(kubectl get deploy "$DEPLOY_NAME" -n "$CANDIDATE_NS" -o jsonpath='{.status.readyReplicas}')
if [ -z "$READY" ] || [ "$READY" -lt 1 ]; then
  echo "❌ Le Deployment $DEPLOY_NAME n'a pas de replica Ready"
  exit 1
fi
echo "✅ Deployment Ready"

SVC_NAME=""
for svc in $(kubectl get svc -n "$CANDIDATE_NS" -o jsonpath='{.items[*].metadata.name}'); do
  TYPE=$(kubectl get svc "$svc" -n "$CANDIDATE_NS" -o jsonpath='{.spec.type}')
  PORTS=$(kubectl get svc "$svc" -n "$CANDIDATE_NS" -o jsonpath='{.spec.ports[*].port}')
  if [ "$TYPE" = "ClusterIP" ] && echo " $PORTS " | grep -q ' 80 '; then
    SVC_NAME="$svc"
    break
  fi
done

if [ -z "$SVC_NAME" ]; then
  echo "❌ Aucun Service ClusterIP exposant le port 80 trouvé dans $CANDIDATE_NS"
  exit 1
fi
echo "✅ Service trouvé : $SVC_NAME (ClusterIP, port 80)"

EXPECTED="${SVC_NAME}.${CANDIDATE_NS}"
ACTUAL=$(kubectl get deploy sensor-array -n death-star -o jsonpath='{.spec.template.spec.containers[?(@.name=="probe-droid")].env[?(@.name=="TARGET_URL")].value}' 2>/dev/null)

if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "❌ TARGET_URL attendu '$EXPECTED' sur death-star/sensor-array (conteneur probe-droid), trouvé '$ACTUAL'"
  exit 1
fi
echo "✅ TARGET_URL correctement défini ($ACTUAL)"

DROID_READY=$(kubectl get deploy sensor-array -n death-star -o jsonpath='{.status.readyReplicas}')
if [ -z "$DROID_READY" ] || [ "$DROID_READY" -lt 1 ]; then
  echo "❌ death-star/sensor-array n'a pas encore de pod Ready après le rollout"
  exit 1
fi

LOGS=$(kubectl logs -n death-star deployment/sensor-array -c probe-droid --tail=50 2>/dev/null)
if ! echo "$LOGS" | grep -q "OK: reponse recue de $EXPECTED"; then
  echo "❌ Pas encore de réponse OK dans les logs de probe-droid pour $EXPECTED"
  echo "Dernières lignes de logs :"
  echo "$LOGS" | tail -5
  echo "(le sidecar teste toutes les 5 secondes, relance la vérification si besoin)"
  exit 1
fi
echo "✅ death-star/sensor-array reçoit bien une réponse de $EXPECTED"

exit 0
