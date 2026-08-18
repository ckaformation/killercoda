# Étape 1 — Créer/supprimer des workloads dans jedi

## Objectif

L'utilisateur **luke** doit pouvoir **créer** et **supprimer** des `pods`, `deployments` et `statefulsets`, mais **uniquement dans le namespace `jedi`**.

## 1. Créer le Role

Un `Role` est toujours limité à un namespace. Comme `pods` (groupe API `core`) et `deployments`/`statefulsets` (groupe API `apps`) appartiennent à des groupes différents, on précise explicitement le groupe pour ces deux dernières ressources (`.apps`), afin d'éviter toute ambiguïté :

`k create role jedi-pod-workload-manager --verb=create,delete --resource=pods,deployments.apps,statefulsets.apps -n jedi`{{exec}}

Tu peux inspecter le résultat :

`k get role jedi-pod-workload-manager -n jedi -o yaml`{{exec}}

## 2. Lier ce Role à luke

Un `Role` seul ne donne aucun droit : il faut le **lier** à un sujet (ici, l'utilisateur `luke`) via un `RoleBinding`, lui aussi limité au namespace `jedi` :

`k create rolebinding luke-jedi-pod-workload-manager --role=jedi-pod-workload-manager --user=luke -n jedi`{{exec}}

## 3. Vérifier avec kubectl auth can-i

Dans le namespace `jedi`, luke doit pouvoir créer et supprimer les trois ressources :

`k auth can-i create pods --as=luke -n jedi`{{exec}}

`k auth can-i delete deployments --as=luke -n jedi`{{exec}}

`k auth can-i create statefulsets --as=luke -n jedi`{{exec}}

Chaque commande doit répondre `yes`.

## 4. Vérifier que ça ne déborde pas ailleurs

Dans un **autre** namespace (`default`), luke ne doit avoir **aucun** de ces droits :

`k auth can-i create pods --as=luke -n default`{{exec}}

Cette commande doit répondre `no`.
