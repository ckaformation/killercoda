# Étape 1 — Créer un Deployment et observer les objets engendrés

Tu vas créer **un seul objet** : un Deployment. Kubernetes en créera deux autres types tout seul.

## 1. Créer le Deployment

Complète la commande suivante (elle n'est pas cliquable : remplace chaque `<A_COMPLETER>` avant de l'exécuter) :

```
k create deployment <A_COMPLETER> --image=<A_COMPLETER> --replicas=<A_COMPLETER>
```

Utilise le nom `snowspeeder`, l'image `nginx:alpine` et `3` réplicas.

## 2. Attendre que les pods soient prêts

`k rollout status deploy snowspeeder`{{exec}}

## 3. Observer les objets engendrés

`k get deploy,rs,pods`{{exec}}

Tu as créé un seul objet, et pourtant tu en vois trois niveaux :

- **1 Deployment** : `snowspeeder`, avec `READY 3/3` ;
- **1 ReplicaSet** : son nom est celui du Deployment suivi d'un hash (`snowspeeder-<hash>`) ;
- **3 pods** : leur nom est celui du ReplicaSet suivi d'un suffixe aléatoire.

Les noms racontent la filiation : Deployment → ReplicaSet → pods.

## 4. Observer les labels des pods

`k get pods --show-labels`{{exec}}

Chaque pod porte deux labels :

- `app=snowspeeder`, ajouté par `k create deployment` ;
- `pod-template-hash=<hash>`, ajouté par le Deployment : c'est le même hash que celui qu'on retrouve dans le nom du ReplicaSet.

## 5. Retrouver ces labels dans les selectors

Un contrôleur sait quels pods lui appartiennent grâce à son **selector** : il gère les pods dont les labels correspondent.

`k get deploy snowspeeder -o wide`{{exec}}

Dans la colonne `SELECTOR`, le Deployment cherche les pods portant `app=snowspeeder`.

`k get rs -o wide`{{exec}}

Dans la colonne `SELECTOR`, le ReplicaSet reprend ce label **et y ajoute** `pod-template-hash=<hash>`. Ce second label lui permet de ne gérer que les pods de sa propre version : c'est essentiel dès qu'un même Deployment possède plusieurs ReplicaSets, ce que tu verras à l'étape 3.
