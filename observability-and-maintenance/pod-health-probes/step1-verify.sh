#!/bin/bash
NS="hoth"
D="echo-base"

fail() { echo "❌ $1"; exit 1; }

# $1 = chemin jsonpath dans le conteneur (ex. readinessProbe.httpGet.path)
get() { kubectl -n "$NS" get deployment "$D" -o jsonpath="{.spec.template.spec.containers[0].$1}" 2>/dev/null; }

kubectl -n "$NS" get deployment "$D" >/dev/null 2>&1 || fail "Le Deployment $D est introuvable dans le namespace $NS."

[ -n "$(get readinessProbe)" ] || fail "Le conteneur de $D n'a pas de readinessProbe. As-tu bien lancé : kubectl apply -f /root/echo-base.yaml ?"

RPATH=$(get readinessProbe.httpGet.path)
[ "$RPATH" = "/healthz" ] || fail "La readinessProbe doit faire un HTTP GET sur /healthz (path obtenu : '$RPATH')."

RPORT=$(get readinessProbe.httpGet.port)
[ "$RPORT" = "80" ] || fail "La readinessProbe doit interroger le port 80 (obtenu : '$RPORT')."

DELAY=$(get readinessProbe.initialDelaySeconds)
[ "$DELAY" = "5" ] || fail "initialDelaySeconds de la readinessProbe doit valoir 5 (obtenu : '$DELAY')."

PERIOD=$(get readinessProbe.periodSeconds)
[ "$PERIOD" = "10" ] || fail "periodSeconds de la readinessProbe doit valoir 10 (obtenu : '$PERIOD')."

kubectl -n "$NS" rollout status deployment/"$D" --timeout=90s >/dev/null 2>&1 || fail "Le rollout de $D n'est pas terminé. Lance : kubectl -n $NS rollout status deployment/$D"

READY=$(kubectl -n "$NS" get deployment "$D" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "${READY:-0}" = "1" ] || fail "Le pod de $D doit être prêt (pods prêts : '${READY:-0}')."

echo "✅ $D a une readinessProbe HTTP GET /healthz:80 (initialDelaySeconds 5, periodSeconds 10) et son pod est prêt."
exit 0
