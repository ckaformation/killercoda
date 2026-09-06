#!/bin/bash
NS="kamino"

if [ ! -f /root/.prep-done ]; then
  echo "❌ L'environnement n'est pas encore prêt"
  exit 1
fi

UNSCHEDULABLE=$(kubectl get node node01 -o jsonpath='{.spec.unschedulable}' 2>/dev/null)
if [ "$UNSCHEDULABLE" != "true" ]; then
  echo "❌ node01 n'est pas cordon (unschedulable != true)"
  exit 1
fi
echo "✅ node01 est cordon"

TOLERATIONS=$(kubectl get statefulset clone-vat -n "$NS" -o jsonpath='{range .spec.template.spec.tolerations[*]}{.key}{"|"}{.effect}{"\n"}{end}' 2>/dev/null)
if ! echo "$TOLERATIONS" | grep -q '^node-role.kubernetes.io/control-plane|NoSchedule$'; then
  echo "❌ Le StatefulSet clone-vat ne déclare pas de toleration pour node-role.kubernetes.io/control-plane:NoSchedule"
  exit 1
fi
echo "✅ Toleration correcte présente sur le StatefulSet"

exit 0
