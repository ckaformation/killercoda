#!/bin/bash
D="echo-base"
S="echo-base"
NS="default"

kubectl get svc "$S" >/dev/null 2>&1 || { echo "Le Service $S n'existe plus (étape 2)."; exit 1; }

for NAME in "$S" "$S.$NS" "$S.$NS.svc.cluster.local"; do
  CODE=$(kubectl exec deploy/"$D" -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$NAME" 2>/dev/null)
  if [ "$CODE" != "200" ]; then
    echo "L'appel de http://$NAME depuis un pod de $D ne répond pas correctement (code HTTP : ${CODE:-aucun})."
    echo "Vérifie que CoreDNS fonctionne : k get pods -n kube-system"
    exit 1
  fi
done

echo "Le Service $S est joignable depuis un pod par son nom court, par $S.$NS et par son FQDN."
exit 0
