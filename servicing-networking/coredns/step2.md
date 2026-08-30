# Étape 2 — Déploiement et découverte de service

Le cluster est sain. Place maintenant à une brique plus classique :
déployer une application et observer comment un pod dans un autre
namespace peut la joindre par son nom, sans connaître son adresse IP.

## 1. Crée les ressources

Dans un **nouveau namespace** de ton choix (par exemple `rebel-base`) :

- un `Deployment` basé sur l'image `nginx:1-alpine`
- un `Service` de type `ClusterIP` qui expose ce déploiement sur le
  port `80`

```
kubectl create namespace rebel-base
```{{exec}}

```
kubectl create deployment comms-relay --image=nginx:1-alpine -n rebel-base
```{{exec}}

```
kubectl expose deployment comms-relay --port=80 --target-port=80 --type=ClusterIP -n rebel-base
```{{exec}}

## 2. Connecte l'application déjà en place

Un autre namespace, `death-star`, contient déjà un déploiement
`sensor-array`. Son conteneur `probe-droid` teste en boucle une cible
définie par la variable d'environnement `TARGET_URL` — pour l'instant
vide.

Définis cette variable sur le déploiement `sensor-array` pour qu'elle
pointe vers **le Service que tu viens de créer** :

```
TARGET_URL=<nom-du-service>.<nom-du-namespace>
```

> C'est le mécanisme de découverte de service "court" de Kubernetes :
> depuis n'importe quel namespace, `<service>.<namespace>` suffit à
> résoudre l'adresse d'un Service, sans avoir besoin du nom pleinement
> qualifié `<service>.<namespace>.svc.cluster.local`.

Exemple (à adapter aux noms que tu as choisis) :

```
kubectl set env deployment/sensor-array -n death-star \
  -c probe-droid TARGET_URL=comms-relay.rebel-base
```{{exec}}

## 3. Vérifie

`kubectl set env` déclenche un nouveau rollout du déploiement
`sensor-array`. Regarde les logs du conteneur `probe-droid` du nouveau
pod :

```
kubectl logs -n death-star deployment/sensor-array -c probe-droid --follow
```{{exec}}

Tu dois voir apparaître des lignes `OK: reponse recue de ...`.
