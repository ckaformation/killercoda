# Étape 2 — Passer à 50 % du trafic

La version canary se comporte bien : on lui envoie maintenant la moitié du trafic, soit 2 pods de chaque côté.

## 1. Ajuster les réplicas

Augmente d'abord la canary :

`kubectl scale deployment x-wing-canary --replicas=2`{{exec}}

`kubectl rollout status deployment/x-wing-canary`{{exec}}

Puis réduis la version actuelle :

`kubectl scale deployment x-wing-current --replicas=2`{{exec}}

> En augmentant la canary **avant** de réduire current, l'application garde toujours au moins 4 pods prêts.

## 2. Vérifier la répartition

`kubectl get pods -L track`{{exec}}

2 pods `current` et 2 pods `canary`.

```
for i in $(seq 1 100); do curl -s http://yavin:30080; done | sort | uniq -c
```{{exec}}

Environ 50 réponses de chaque version.
