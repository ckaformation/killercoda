#!/bin/bash
NS="falco"

VALUES_YAML=$(helm get values falco -n "$NS" 2>/dev/null)
if echo "$VALUES_YAML" | grep -q "log_level: debug"; then
  echo "❌ falco.log_level est encore sur 'debug' — le rollback n'a pas fonctionné"
  exit 1
fi
if ! echo "$VALUES_YAML" | grep -q "log_level: warning"; then
  echo "❌ falco.log_level attendu 'warning' après rollback, introuvable dans les values :"
  echo "$VALUES_YAML"
  exit 1
fi
echo "✅ falco.log_level revenu à 'warning' après rollback"

REVISION=$(helm history falco -n "$NS" --max 100 2>/dev/null | tail -n1 | awk '{print $1}')
if [ -z "$REVISION" ] || [ "$REVISION" -lt 3 ] 2>/dev/null; then
  echo "❌ Aucune nouvelle révision de rollback détectée (révision actuelle: '$REVISION')"
  exit 1
fi
echo "✅ Rollback effectué (nouvelle révision $REVISION, contenu de la révision 1)"

exit 0
