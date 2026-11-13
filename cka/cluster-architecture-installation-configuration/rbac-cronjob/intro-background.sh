#!/bin/bash
# ============================================================================
# Préparation silencieuse :
#   - lien symbolique k -> kubectl (cf. rbac-luke-jedi)
#   - namespace "ops"
#   - ServiceAccount "leon", SANS RBAC associé : c'est le problème à
#     résoudre par l'élève
#   - CronJob "nettoyeur" utilisant ce ServiceAccount, censé supprimer les
#     pods Completed du namespace ops (échouera tant que "leon" n'a pas les
#     droits nécessaires), planifié normalement (toutes les minutes).
#   - Le jobTemplate utilise restartPolicy: Never + backoffLimit: 0, pour
#     qu'un échec d'un Job donné s'arrête après une seule tentative (pas de
#     redémarrage de conteneur en boucle, pas de nouveau pod recréé par ce
#     Job) — le CronJob continuera néanmoins à créer un nouveau Job à
#     chaque tick de sa planification, comme un CronJob normal.
#   - terminationGracePeriodSeconds: 1 sur le jobTemplate, pour que les
#     pods (notamment ceux en échec) se terminent rapidement plutôt que
#     d'attendre les 30s de grace period par défaut.
#   - 3 pods busybox ("echo done") qui atteignent rapidement l'état
#     Completed : ce sont les pods cibles du nettoyage
# ============================================================================

ln -sf "$(which kubectl)" /usr/local/bin/k

kubectl create namespace ops
kubectl create serviceaccount leon -n ops

kubectl run pod-a-nettoyer-1 --image=busybox --restart=Never -n ops --command -- echo done
kubectl run pod-a-nettoyer-2 --image=busybox --restart=Never -n ops --command -- echo done
kubectl run pod-a-nettoyer-3 --image=busybox --restart=Never -n ops --command -- echo done

cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nettoyeur
  namespace: ops
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      backoffLimit: 0
      template:
        spec:
          serviceAccountName: leon
          restartPolicy: Never
          terminationGracePeriodSeconds: 1
          containers:
          - name: nettoyeur
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - kubectl delete pods --field-selector=status.phase=Succeeded -n ops
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/pod-a-nettoyer-1 -n ops --timeout=60s
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/pod-a-nettoyer-2 -n ops --timeout=60s
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/pod-a-nettoyer-3 -n ops --timeout=60s

exit 0
