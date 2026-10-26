# Étape 1 — Changer la stratégie de rollout et déployer une nouvelle version

Le Deployment `millennium-falcon` utilise la stratégie `Recreate` : à chaque mise à jour, **tous** les anciens pods sont arrêtés avant que les nouveaux ne démarrent, ce qui coupe le service pendant un instant. On veut une mise à jour progressive qui ne fait jamais descendre le nombre de pods disponibles sous 2.

## 0. Attendre que l'environnement soit prêt

`/root/wait-for-prep.sh`{{exec}}

Cette commande attend la fin de la préparation de l'environnement. Attends qu'elle affiche « C'est pret ! » avant de continuer.

`kubectl get deployments`{{exec}}

Tu dois voir `millennium-falcon`, `death-star` et `tie-fighter`.

## 1. Observer l'état actuel

`kubectl get deployment millennium-falcon -o jsonpath='{.spec.strategy}'`{{exec}}

Tu dois voir le type `Recreate`.

`kubectl rollout history deployment/millennium-falcon`{{exec}}

Il n'y a qu'une seule révision pour le moment.

## 2. Passer en RollingUpdate

`kubectl edit deployment millennium-falcon`{{exec}}

Repère la section `spec.strategy` et remplace-la en complétant les valeurs ci-dessous (ce bloc n'est pas cliquable) :

```
strategy:
  type: <A_COMPLETER>
  rollingUpdate:
    maxSurge: <A_COMPLETER>
    maxUnavailable: <A_COMPLETER>
```

Les valeurs attendues sont : type `RollingUpdate`, `maxSurge` à `1` et `maxUnavailable` à `0`.

- `maxSurge: 1` autorise un pod de plus que le nombre de réplicas souhaité pendant la mise à jour (jusqu'à 3 pods ici) ;
- `maxUnavailable: 0` interdit de passer sous le nombre de réplicas souhaité : il y a toujours 2 pods disponibles.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

> Pour passer de `Recreate` à `RollingUpdate`, il faut ajouter le bloc `rollingUpdate`. Dans l'autre sens, ce bloc doit être supprimé : l'API refuse un bloc `rollingUpdate` avec la stratégie `Recreate`.

`kubectl get deployment millennium-falcon -o jsonpath='{.spec.strategy}'`{{exec}}

`kubectl rollout history deployment/millennium-falcon`{{exec}}

Il y a toujours une seule révision : modifier la stratégie ne crée pas de nouvelle révision, car elle ne fait pas partie du pod template.

## 3. Déployer une nouvelle version

Change maintenant la valeur de la variable `APP_RELEASE` (elle vaut `v2`). Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
kubectl set env deployment/millennium-falcon APP_RELEASE=<A_COMPLETER>
```

Utilise la valeur `v3`. Modifier une variable d'environnement modifie le pod template, ce qui déclenche un rollout.

## 4. Suivre le rollout

`kubectl rollout status deployment/millennium-falcon`{{exec}}

Cette commande attend la fin du rollout et affiche sa progression. Quand elle rend la main, tous les pods ont été remplacés.

## 5. Observer le résultat

`kubectl get rs -l app=millennium-falcon`{{exec}}

L'ancien ReplicaSet est à 0 réplica et le nouveau à 2.

`kubectl rollout history deployment/millennium-falcon`{{exec}}

Il y a maintenant deux révisions.

`kubectl describe deployment millennium-falcon`{{exec}}

Regarde la section `Events` en bas : les deux ReplicaSets montent et descendent par paliers d'un pod, au lieu que l'ancien soit supprimé d'un coup comme avec `Recreate`.
