# Étape 4 — Appeler le Service par son nom (DNS)

Dans un cluster, les applications s'appellent rarement par `CLUSTER-IP` : elles utilisent le **nom** du Service, résolu par le DNS du cluster (CoreDNS). Tu vas appeler `echo-base` depuis l'intérieur d'un de ses propres pods.

## 1. Appeler le Service par son nom court

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par le nom du Service) :

```
k exec deploy/echo-base -- curl -s <A_COMPLETER>
```

`k exec deploy/echo-base` exécute la commande dans l'un des pods du Deployment. Ça fonctionne : le nom court du Service (`echo-base`) est résolu en sa `CLUSTER-IP`.

## 2. Appeler le Service avec son namespace

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par `<nom du Service>.<namespace>`, ici le namespace est `default`) :

```
k exec deploy/echo-base -- curl -s <A_COMPLETER>
```

Ça fonctionne aussi. Ce format est indispensable pour appeler un Service d'un **autre** namespace.

## 3. Comprendre la nomenclature : le FQDN d'un Service

Le nom complet (FQDN) d'un Service a toujours cette forme :

```
echo-base . default . svc . cluster.local
    |          |       |         |
    |          |       |         └─ domaine du cluster (cluster.local par défaut)
    |          |       └─ "svc" : indique qu'il s'agit d'un Service
    |          └─ namespace du Service
    └─ nom du Service
```

Mais alors, pourquoi `echo-base` ou `echo-base.default` suffisent-ils ? Regarde la configuration DNS du pod :

`k exec deploy/echo-base -- cat /etc/resolv.conf`{{exec}}

- `nameserver` est l'adresse du serveur DNS du cluster : c'est la `CLUSTER-IP` du Service `kube-dns` (CoreDNS), que tu peux vérifier juste après cette liste ;
- `search` est la liste des suffixes que le résolveur ajoute à un nom court avant de l'interroger. Elle commence par `<namespace du pod>.svc.<domaine>`, puis `svc.<domaine>`, puis `<domaine>`. Ainsi, `echo-base` devient `echo-base.default.svc.cluster.local`, et `echo-base.default` aussi, grâce au suffixe `svc.cluster.local` ;
- `options ndots:5` indique que tout nom contenant moins de 5 points est d'abord essayé avec chacun des suffixes de la liste `search`.

`k get svc kube-dns -n kube-system`{{exec}}

Conséquence : le nom court ne fonctionne que dans le **même namespace** que le Service. Depuis un autre namespace, il faut au minimum `<service>.<namespace>`.

## 4. Appeler le Service avec son FQDN

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par le FQDN complet du Service, avec le domaine affiché dans `resolv.conf`) :

```
k exec deploy/echo-base -- curl -s <A_COMPLETER>
```
