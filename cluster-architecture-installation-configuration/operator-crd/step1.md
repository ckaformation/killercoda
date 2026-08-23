# Étape 1 — Installer l'opérateur

## 1. Examiner ce que tu vas installer

`cat /root/operator/operator.yaml`{{exec}}

Ce fichier contient, dans l'ordre :

- un namespace `operators`, où vivra l'opérateur lui-même (séparé des namespaces qu'il gère) ;
- un `ServiceAccount` dédié ;
- un `ClusterRole` donnant les droits `get`/`list`/`watch` sur les futures ressources `greetings` (notre CRD, créée à l'étape 2) et `get`/`list`/`create` sur les `configmaps` ;
- **trois `RoleBinding`** — un par namespace cible (`luke`, `ben`, `leia`) — liant ce `ServiceAccount` à ce `ClusterRole`. C'est la même technique que dans le scénario RBAC `rbac-luke-jedi` : un `ClusterRole` réutilisé dans plusieurs `RoleBinding` namespacés, pour scoper précisément les droits sans `ClusterRoleBinding` (qui, lui, s'appliquerait à tout le cluster).
- un `Deployment` : le "corps" de l'opérateur, un script shell qui boucle toutes les 10 secondes sur `luke`, `ben` et `leia`, cherche des ressources `Greeting`, et crée une `ConfigMap` pour chacune qui n'en a pas encore.

## 2. Installer l'opérateur

`kubectl apply -f /root/operator/operator.yaml`{{exec}}

## 3. Vérifier qu'il tourne

`k get pods -n operators`{{exec}}

Le pod doit passer à l'état `Running`.

`k logs -n operators deployment/greeting-operator`{{exec}}

Tu devrais voir le message de démarrage. Pour l'instant, l'opérateur ne fait rien de plus : la CRD `Greeting` n'existe pas encore (étape 2), donc il n'y a rien à réconcilier.

## 4. Vérifier le périmètre RBAC

L'opérateur doit pouvoir agir sur `luke`, `ben` et `leia`, mais nulle part ailleurs :

`k auth can-i create configmaps --as=system:serviceaccount:operators:greeting-operator -n luke`{{exec}}

`k auth can-i create configmaps --as=system:serviceaccount:operators:greeting-operator -n ben`{{exec}}

`k auth can-i create configmaps --as=system:serviceaccount:operators:greeting-operator -n leia`{{exec}}

Les trois doivent répondre `yes`.

`k auth can-i create configmaps --as=system:serviceaccount:operators:greeting-operator -n default`{{exec}}

Celle-ci doit répondre `no`.
