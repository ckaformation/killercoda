#!/bin/bash
NS="hoth"
D="echo-base"
FILE="/tmp/life-signs"

fail() { echo "❌ $1"; exit 1; }

kubectl -n "$NS" get deployment "$D" >/dev/null 2>&1 || fail "Le Deployment $D est introuvable dans le namespace $NS."

# La livenessProbe de l'etape 2 doit etre restee en place.
CMD=$(kubectl -n "$NS" get deployment "$D" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.exec.command[*]}' 2>/dev/null)
case "$CMD" in
  *"stat $FILE"*) ;;
  *) fail "La livenessProbe de l'étape 2 a disparu ou a changé (commande obtenue : '$CMD') : garde-la telle quelle." ;;
esac

POD=$(kubectl -n "$NS" get pods -l app="$D" --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -n "$POD" ] || fail "Aucun pod de $D n'est en cours d'exécution. Attends quelques secondes puis relance la vérification."

# Un conteneur redemarre, et pas un pod recree (un pod neuf repart a 0).
RESTARTS=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null)
[ "${RESTARTS:-0}" -ge 1 ] 2>/dev/null || fail "Le conteneur du pod $POD n'a jamais redémarré (RESTARTS : '${RESTARTS:-0}'). Supprime $FILE dans le conteneur (sans supprimer le pod), attends une dizaine de secondes, puis relance la vérification."

# Le redemarrage doit venir de la livenessProbe.
if ! kubectl -n "$NS" get events -o jsonpath='{range .items[*]}{.involvedObject.name} {.message}{"\n"}{end}' 2>/dev/null | grep "^$POD " | grep -qi "liveness probe"; then
  fail "Le conteneur du pod $POD a redémarré, mais aucun échec de livenessProbe n'est enregistré dans ses événements. Supprime $FILE dans le conteneur, attends une dizaine de secondes, puis relance la vérification."
fi

READY=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$READY" = "True" ] || fail "Le conteneur a bien été redémarré, mais le pod $POD n'est pas encore prêt (readinessProbe). Attends quelques secondes puis relance la vérification."

kubectl -n "$NS" exec "$POD" -- stat "$FILE" >/dev/null 2>&1 || fail "$FILE est absent du conteneur : il vient sans doute d'être supprimé à nouveau. Attends le redémarrage du conteneur (une dizaine de secondes), puis relance la vérification."

echo "✅ La livenessProbe a échoué, le kubelet a redémarré le conteneur du pod $POD (RESTARTS : $RESTARTS) et $FILE a été recréé au démarrage."
exit 0
