# Étape 1 — Ajouter un label spécifique sur node01

## 1. Observer l'état actuel

`k get nodes --show-labels`{{exec}}

Les deux nœuds partagent déjà le label `side=dark`.

## 2. Ajouter un label propre à node01

`kubectl label node node01 order=sith`{{exec}}

## 3. Vérifier

`k get nodes --show-labels`{{exec}}

Seul `node01` doit maintenant afficher à la fois `side=dark` **et** `order=sith`. `controlplane` ne porte toujours que `side=dark`.
