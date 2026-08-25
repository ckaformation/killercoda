# Étape 1 — Taint NoSchedule sur controlplane

## 1. Ajouter le taint

`kubectl taint nodes controlplane empire=occupied:NoSchedule`{{exec}}

`k describe node controlplane | grep -A2 Taints`{{exec}}

## 2. Forcer un rollout pour observer l'effet sur les deux Deployments

Un taint n'affecte que les **futures** décisions de placement : les pods déjà en place, où qu'ils soient, ne bougent pas tout seuls avec `NoSchedule`. Pour observer clairement l'effet du taint sur les deux Deployments, on force un nouveau rollout sur les deux :

`kubectl rollout restart deployment/millennium-falcon deployment/x-wing-squadron`{{exec}}

`kubectl rollout status deployment/millennium-falcon`{{exec}}

`kubectl rollout status deployment/x-wing-squadron`{{exec}}

## 3. Observer

`k get pods -l 'app in (millennium-falcon,x-wing-squadron)' -o wide`{{exec}}

Aucun des deux Deployments ne tolère encore ce taint : les 4 pods (2 + 2) doivent tous se retrouver sur `node01`. C'est notre point de départ propre pour la suite.
