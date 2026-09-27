#!/bin/bash
NS="falco"

VALUES_YAML=$(helm get values falco -n "$NS" 2>/dev/null)
if ! echo "$VALUES_YAML" | grep -q "log_level: debug"; then
  echo "❌ falco.log_level attendu 'debug', introuvable dans les values :"
  echo "$VALUES_YAML"
  exit 1
fi
echo "✅ falco.log_level correctement mis à jour (debug)"

REVISION=$(helm history falco -n "$NS" --max 100 2>/dev/null | tail -n1 | awk '{print $1}')
if [ -z "$REVISION" ] || [ "$REVISION" -lt 2 ] 2>/dev/null; then
  echo "❌ Aucune révision d'upgrade détectée (révision actuelle: '$REVISION')"
  exit 1
fi
echo "✅ Release à la révision $REVISION (upgrade effectué)"

exit 0
