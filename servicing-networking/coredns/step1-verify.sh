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

echo "Test fonctionnel de résolution DNS depuis un pod..."
kubectl delete pod dns-check -n default --ignore-not-found >/dev/null 2>&1
kubectl run dns-check -n default --image=busybox:1.36 --restart=Never --command -- sh -c "nslookup kubernetes.default" >/dev/null 2>&1

for i in $(seq 1 20); do
  PHASE=$(kubectl get pod dns-check -n default -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$PHASE" = "Succeeded" ] || [ "$PHASE" = "Failed" ]; then
    break
  fi
  sleep 2
done

DNS_OUT=$(kubectl logs dns-check -n default 2>/dev/null)
kubectl delete pod dns-check -n default --ignore-not-found >/dev/null 2>&1

if ! echo "$DNS_OUT" | grep -q "kubernetes.default.svc.cluster.local"; then
  echo "❌ La résolution DNS depuis un pod échoue encore"
  echo "Sortie du test : $DNS_OUT"
  exit 1
fi
echo "✅ Résolution DNS fonctionnelle depuis un pod de test"

exit 0
