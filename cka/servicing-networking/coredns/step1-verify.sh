#!/bin/bash
if [ ! -f /root/.prep-done ]; then
  echo "❌ L'environnement n'est pas encore prêt"
  exit 1
fi

COREFILE=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' 2>/dev/null)
if echo "$COREFILE" | grep -q "holocron"; then
  echo "❌ Le ConfigMap coredns contient encore la directive inconnue 'holocron'"
  exit 1
fi
echo "✅ Le Corefile ne contient plus la directive inconnue"

echo "Attente de la stabilisation du Deployment coredns..."
if ! kubectl -n kube-system rollout status deployment/coredns --timeout=90s; then
  echo "❌ Le Deployment coredns n'est pas stabilisé (toujours en CrashLoopBackOff ?)"
  exit 1
fi
echo "✅ Deployment coredns stabilisé"

READY=$(kubectl -n kube-system get pods -l k8s-app=kube-dns -o jsonpath='{range .items[*]}{.status.containerStatuses[0].ready}{"\n"}{end}' | grep -c '^true$')
TOTAL=$(kubectl -n kube-system get pods -l k8s-app=kube-dns -o jsonpath='{.items[*].metadata.name}' | wc -w)
if [ "$READY" -lt 1 ] || [ "$READY" -ne "$TOTAL" ]; then
  echo "❌ Tous les pods CoreDNS ne sont pas Ready ($READY/$TOTAL)"
  exit 1
fi
echo "✅ Tous les pods CoreDNS sont Ready ($READY/$TOTAL)"

exit 0
