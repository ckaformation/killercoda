# Étape 2 — Scaler le Deployment et supprimer un pod

## 1. Passer le Deployment à 5 réplicas

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
k scale deploy snowspeeder --replicas=<A_COMPLETER>
```

Utilise la valeur `5`. Cette commande modifie le champ `spec.replicas` du **Deployment** : c'est l'état désiré qui change.

`k rollout status deploy snowspeeder`{{exec}}

`k get deploy,rs,pods`{{exec}}

Le Deployment affiche `READY 5/5`, et il y a 5 pods. Remarque qu'il n'y a **toujours qu'un seul ReplicaSet** : changer le nombre de réplicas ne modifie pas le modèle de pod (le *pod template*), donc ne crée pas de nouveau ReplicaSet.

## 2. Supprimer un pod

`k get pods`{{exec}}

Choisis l'un des pods et note son nom. Complète ensuite la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par le nom du pod) :

```
k delete pod <A_COMPLETER>
```

## 3. Constater le remplacement

Relance tout de suite la commande suivante :

`k get pods`{{exec}}

Tu dois voir 5 pods en cours d'exécution (ou en cours de démarrage) :

- le pod supprimé n'est plus là (ou est en `Terminating` pendant quelques secondes) ;
- un **nouveau pod**, avec un autre nom et un `AGE` de quelques secondes, a pris sa place.

Pourquoi ? Le Deployment demande 5 réplicas. En supprimant un pod, tu as créé un écart entre l'état désiré (5) et l'état réel (4) : le ReplicaSet l'a constaté et a créé un pod pour le combler. C'est la boucle de réconciliation, et la différence avec le pod « nu » du scénario précédent, qui, lui, ne serait jamais revenu.

`k get rs`{{exec}}

C'est toujours le même ReplicaSet qui gère les 5 pods.

## 4. Voir qui a créé les pods

`k get events --field-selector reason=SuccessfulCreate`{{exec}}

Chaque événement `Created pod` correspond à un pod créé par le ReplicaSet : les 3 du départ, les 2 du scaling, et celui qui remplace le pod supprimé.
