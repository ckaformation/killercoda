# Étape 3 — Un pod en CrashLoopBackOff après la dernière révision

Le Deployment `tie-fighter` a connu quatre déploiements successifs. Depuis le dernier, l'application est indisponible. Ce Deployment n'a qu'un seul réplica et utilise la stratégie `Recreate`.

## 1. Constater le problème

`kubectl get pods -l app=tie-fighter`{{exec}}

Il n'y a qu'un seul pod, et il est en `CrashLoopBackOff` (ou en `Error` juste avant) : il démarre, plante, redémarre en boucle et n'est jamais prêt (`0/1`).

`kubectl get deployment tie-fighter`{{exec}}

La colonne `READY` affiche `0/1` et `AVAILABLE` affiche `0` : plus aucun pod ne sert l'application.

Il n'y a pas d'ancien pod resté en service à côté : avec la stratégie `Recreate`, l'ancien pod a été arrêté **avant** que le nouveau ne démarre.

`kubectl get rs -l app=tie-fighter`{{exec}}

## 2. Observer les révisions

`kubectl rollout history deployment/tie-fighter`{{exec}}

Tu dois voir 4 révisions. La colonne `CHANGE-CAUSE` décrit chacune d'elles.

Compare maintenant le contenu de la révision 2 et celui de la révision 4 :

`kubectl rollout history deployment/tie-fighter --revision=2`{{exec}}

`kubectl rollout history deployment/tie-fighter --revision=4`{{exec}}

Repère ce qui distingue la révision 4 des autres.

## 3. Revenir à la révision 2

On décide de revenir à la révision 2. Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
kubectl rollout undo deployment/tie-fighter --to-revision=<A_COMPLETER>
```

Utilise le numéro `2`. Sans l'option `--to-revision`, `rollout undo` reviendrait à la révision précédente (ici la 3).

## 4. Suivre le rollback

`kubectl rollout status deployment/tie-fighter`{{exec}}

## 5. Constater que le pod n'est plus en erreur

`kubectl get pods -l app=tie-fighter`{{exec}}

Le pod est `Running` et prêt (`1/1`) : plus de `CrashLoopBackOff`.

`kubectl get deployment tie-fighter`{{exec}}

`READY` et `AVAILABLE` sont revenus à 1 : l'application est de nouveau disponible.

`kubectl get deployment tie-fighter -o jsonpath='{.spec.template.spec.containers[0].env[0].value}'`{{exec}}

Tu dois voir `v2` : le contenu de la révision 2 est restauré.

`kubectl rollout history deployment/tie-fighter`{{exec}}

> Regarde les numéros affichés : la révision 2 n'apparaît plus sous ce numéro. Kubernetes ne fait jamais reculer un numéro de révision : le rollback reprend le contenu de la révision 2 et l'enregistre comme **nouvelle** révision (la plus haute, ici la 5). C'est le contenu qui est restauré, pas le numéro.
