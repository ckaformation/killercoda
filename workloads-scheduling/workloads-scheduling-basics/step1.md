# Étape 1 — Déployer un Pod nu

Pas de Deployment, pas de StatefulSet : juste un `Pod`, l'objet le plus élémentaire de charge applicative dans Kubernetes.

## 1. Créer le pod

`kubectl run r2d2 --image=nginx:alpine`{{exec}}

## 2. Vérifier

`k get pod r2d2 -o wide`{{exec}}

Le pod doit passer à l'état `Running`.

`k get pod r2d2 -o jsonpath='{.metadata.ownerReferences}'`{{exec}}

Cette dernière commande doit renvoyer une sortie **vide** : contrairement à un pod issu d'un Deployment ou d'un StatefulSet, celui-ci n'a aucun contrôleur parent. Si tu le supprimes, personne ne le recrée à ta place — on le vérifiera par contraste à l'étape suivante.
