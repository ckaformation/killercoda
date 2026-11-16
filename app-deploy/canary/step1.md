# Étape 1 — Déployer la version canary avec 25 % du trafic

On veut faire tourner la nouvelle version (`version : Canary`) à côté de l'actuelle, en ne lui envoyant que 25 % du trafic. Avec 4 pods au total, il suffit d'en avoir 3 en current et 1 en canary.

## 0. Attendre que l'environnement soit prêt

`/root/wait-for-prep.sh`{{exec}}

Attends qu'elle affiche « C'est pret ! » avant de continuer.

## 1. Observer l'état actuel

`kubectl get pods -L track`{{exec}}

La colonne `TRACK` affiche le label `track` de chaque pod : les 4 pods sont en `current`.

`kubectl get svc x-wing -o wide`{{exec}}

Le selector du Service est `app=x-wing`, sans `track` : tout pod qui porte `app=x-wing` reçoit du trafic, quelle que soit sa version.

`grep yavin /etc/hosts`{{exec}}

Le nom `yavin` pointe vers l'IP du nœud, sur laquelle le NodePort 30080 est ouvert.

Appelle le Service 100 fois et compte les réponses :

```
for i in $(seq 1 100); do curl -s http://yavin:30080; done | sort | uniq -c
```{{exec}}

Les 100 réponses sont `version : Current`.

## 2. Préparer le manifeste de la version canary

Pars d'une copie du manifeste de la version actuelle :

`cp /root/x-wing-current.yaml /root/x-wing-canary.yaml`{{exec}}

Remplace `current` par `canary` partout dans la copie :

`sed -i 's/current/canary/g' /root/x-wing-canary.yaml`{{exec}}

Passe le nombre de réplicas de 4 à 1 :

`sed -i 's/replicas: 4/replicas: 1/' /root/x-wing-canary.yaml`{{exec}}

Compare les deux fichiers :

`diff /root/x-wing-current.yaml /root/x-wing-canary.yaml`{{exec}}

Six lignes changent :

- le nom du Deployment : `x-wing-canary` ;
- le label `track` dans `metadata`, dans le `selector` et dans le `template` : `canary` ;
- la ConfigMap montée : `x-wing-canary-page` ;
- `replicas: 1`.

> Le label `app: x-wing` ne change pas : c'est lui que vise le Service. Le label `track`, lui, doit changer **aussi dans le selector**, sinon les deux Deployments se disputeraient les mêmes pods.
>
> Dans vi, le même remplacement se fait avec `:%s/current/canary/g`.

## 3. Ramener la version actuelle à 3 réplicas

`kubectl scale deployment x-wing-current --replicas=3`{{exec}}

## 4. Déployer la version canary

`kubectl apply -f /root/x-wing-canary.yaml`{{exec}}

`kubectl rollout status deployment/x-wing-canary`{{exec}}

## 5. Vérifier la répartition

`kubectl get pods -L track`{{exec}}

3 pods `current` et 1 pod `canary`.

`kubectl get endpointslices -l kubernetes.io/service-name=x-wing`{{exec}}

Le Service a 4 endpoints : les pods des deux versions.

```
for i in $(seq 1 100); do curl -s http://yavin:30080; done | sort | uniq -c
```{{exec}}

Environ 75 `version : Current` et 25 `version : Canary`. Chaque requête est envoyée au hasard vers l'un des 4 pods prêts : les chiffres varient un peu d'un essai à l'autre.
