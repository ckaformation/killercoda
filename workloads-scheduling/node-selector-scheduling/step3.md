# Étape 3 — Retirer le label sur controlplane et observer

## 1. Retirer le label

Le tiret final supprime un label :

`kubectl label node controlplane side-`{{exec}}

`k get nodes --show-labels`{{exec}}

`controlplane` ne porte plus aucun des deux labels utilisés par nos `nodeSelector`.

## 2. Relancer les deux Deployments

Retirer un label ne bouge pas les pods déjà en place : `nodeSelector` n'est vérifié qu'au moment du scheduling, pas en continu. Il faut forcer un nouveau rollout pour que les pods soient replanifiés :

`kubectl rollout restart deployment/rebel-fleet deployment/imperial-garrison`{{exec}}

`kubectl rollout status deployment/rebel-fleet`{{exec}}

`kubectl rollout status deployment/imperial-garrison`{{exec}}

## 3. Observer

`k get pods -l 'app in (rebel-fleet,imperial-garrison)' -o wide`{{exec}}

Les 4 pods (2 + 2) doivent maintenant être **tous** sur `node01` : `controlplane` ne porte plus `side=dark`, donc `rebel-fleet` n'a lui non plus plus qu'un seul nœud éligible — le même que `imperial-garrison`.
