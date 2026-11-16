# Étape 3 — Passer à 100 % du trafic

La version canary est validée : tout le trafic doit maintenant aller vers elle.

## 1. Ajuster les réplicas

`kubectl scale deployment x-wing-canary --replicas=4`{{exec}}

`kubectl rollout status deployment/x-wing-canary`{{exec}}

`kubectl scale deployment x-wing-current --replicas=0`{{exec}}

## 2. Vérifier la répartition

`kubectl get pods -L track`{{exec}}

Il ne reste que 4 pods `canary`. Si des pods `current` apparaissent encore, ils sont en cours d'arrêt : relance la commande.

```
for i in $(seq 1 100); do curl -s http://yavin:30080; done | sort | uniq -c
```{{exec}}

Les 100 réponses sont `version : Canary`.

## 3. Garder un retour arrière possible

`kubectl get deployments`{{exec}}

`x-wing-current` existe toujours, avec 0 réplica. En cas de problème, il suffirait de le remonter pour renvoyer du trafic vers l'ancienne version (ne le fais pas maintenant) :

```
kubectl scale deployment x-wing-current --replicas=4
```
