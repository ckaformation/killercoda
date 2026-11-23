#!/bin/bash
NS="hoth"
D="echo-base"
FILE="/tmp/life-signs"

fail() { echo "❌ $1"; exit 1; }

# $1 = chemin jsonpath dans le conteneur (ex. livenessProbe.periodSeconds)
get() { kubectl -n "$NS" get deployment "$D" -o jsonpath="{.spec.template.spec.containers[0].$1}" 2>/dev/null; }

kubectl -n "$NS" get deployment "$D" >/dev/null 2>&1 || fail "Le Deployment $D est introuvable dans le namespace $NS."

# La readinessProbe de l'etape 1 doit toujours etre la.
RPATH=$(get readinessProbe.httpGet.path)
[ "$RPATH" = "/healthz" ] || fail "La readinessProbe de l'étape 1 a disparu ou a changé (path obtenu : '$RPATH') : garde-la telle quelle."

[ -n "$(get livenessProbe)" ] || fail "Le conteneur de $D n'a pas de livenessProbe. As-tu bien lancé : kubectl apply -f /root/echo-base.yaml ?"

CMD=$(get 'livenessProbe.exec.command[*]')
case "$CMD" in
  *"stat $FILE"*) ;;
  *) fail "La livenessProbe doit exécuter la commande 'stat $FILE' (commande obtenue : '$CMD')." ;;
esac

DELAY=$(get livenessProbe.initialDelaySeconds)
[ "$DELAY" = "10" ] || fail "initialDelaySeconds de la livenessProbe doit valoir 10 (obtenu : '$DELAY')."

PERIOD=$(get livenessProbe.periodSeconds)
[ "$PERIOD" = "7" ] || fail "periodSeconds de la livenessProbe doit valoir 7 (obtenu : '$PERIOD')."

THRESHOLD=$(get livenessProbe.failureThreshold)
[ "$THRESHOLD" = "1" ] || fail "failureThreshold de la livenessProbe doit valoir 1 (obtenu : '$THRESHOLD')."

kubectl -n "$NS" rollout status deployment/"$D" --timeout=90s >/dev/null 2>&1 || fail "Le rollout de $D n'est pas terminé. Lance : kubectl -n $NS rollout status deployment/$D"

READY=$(kubectl -n "$NS" get deployment "$D" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" = "1" ] || fail "Le pod de $D doit être prêt (pods prêts : '${READY:-0}')."

echo "✅ $D a une livenessProbe exec 'stat $FILE' (initialDelaySeconds 10, periodSeconds 7, failureThreshold 1), en plus de sa readinessProbe."
exit 0
