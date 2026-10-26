# Étape 3 — Un pod en CrashLoopBackOff après la dernière révision

Le Deployment `tie-fighter` a connu quatre déploiements successifs. Depuis le dernier, l'un de ses pods ne démarre pas.

## 1. Constater le problème

`kubectl get pods -l app=tie-fighter`{{exec}}

Tu dois voir deux pods `Running` (l'ancienne version, toujours en service) et un pod en `CrashLoopBackOff` ou `Error` (la nouvelle). S'il n'y a pas encore de pod en erreur, ou si la liste est incomplète, la préparation n'est peut-être pas terminée : attends quelques secondes et relance la commande.

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

Il n'y a plus de pod en `CrashLoopBackOff`, et tous les pods sont `Running`.

`kubectl get deployment tie-fighter -o jsonpath='{.spec.template.spec.containers[0].env[0].value}'`{{exec}}

Tu dois voir `v2` : le contenu de la révision 2 est restauré.

`kubectl rollout history deployment/tie-fighter`{{exec}}

> Regarde les numéros affichés : la révision 2 n'apparaît plus sous ce numéro. Kubernetes ne fait jamais reculer un numéro de révision : le rollback reprend le contenu de la révision 2 et l'enregistre comme **nouvelle** révision (la plus haute, ici la 5). C'est le contenu qui est restauré, pas le numéro.
