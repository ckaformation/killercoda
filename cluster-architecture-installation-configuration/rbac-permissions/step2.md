# Étape 2 — Accès en lecture (view) hors des namespaces kube-*

## Objectif

L'utilisateur **luke** doit pouvoir **consulter** (droits en lecture seule) **tous les namespaces existants**, sauf ceux dont le nom commence par `kube-` (`kube-system`, `kube-public`, `kube-node-lease`, etc.).

## Pourquoi ce n'est pas un simple ClusterRoleBinding

RBAC ne permet pas d'exprimer "tous les namespaces sauf ceux qui matchent tel motif" : un `ClusterRoleBinding` s'applique à **tous** les namespaces sans exception possible, et un `RoleBinding` ne s'applique qu'à **un seul** namespace. Il n'existe pas de mécanisme d'exclusion dans l'API RBAC elle-même.

La solution : créer un `RoleBinding` **dans chaque namespace concerné**, en s'appuyant sur le `ClusterRole` `view` fourni nativement par Kubernetes (avec les autres rôles par défaut `edit`, `admin`, `cluster-admin`).

## 1. Lister les namespaces actuels

`k get namespaces`{{exec}}

## 2. Créer un RoleBinding "view" dans chaque namespace, sauf kube-*

Cette commande liste les namespaces, exclut ceux qui commencent par `kube-`, et crée un `RoleBinding` liant luke au `ClusterRole` `view` dans chacun des namespaces restants :

`for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v '^kube-'); do kubectl create rolebinding luke-view-$ns --clusterrole=view --user=luke -n $ns; done`{{exec}}

> Cette approche a une limite à connaître : si un **nouveau** namespace est créé plus tard, il n'aura pas automatiquement de RoleBinding pour luke — il faudrait relancer cette commande (ou l'automatiser via un contrôleur/CronJob, hors périmètre de ce scénario).

## 3. Vérifier avec kubectl auth can-i

Dans `default` et `jedi`, luke doit pouvoir lire les pods :

`k auth can-i get pods --as=luke -n default`{{exec}}

`k auth can-i get pods --as=luke -n jedi`{{exec}}

Chaque commande doit répondre `yes`.

## 4. Vérifier l'exclusion des namespaces kube-*

`k auth can-i get pods --as=luke -n kube-system`{{exec}}

Cette commande doit répondre `no`.
