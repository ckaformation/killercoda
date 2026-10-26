# Étape 1 — Changer la stratégie de rollout et déployer une nouvelle version

Le Deployment `millennium-falcon` utilise la stratégie `Recreate` : à chaque mise à jour, **tous** les anciens pods sont arrêtés avant que les nouveaux ne démarrent, ce qui coupe le service pendant un instant. On veut une mise à jour progressive qui ne fait jamais descendre le nombre de pods disponibles sous 2, et déployer en même temps une nouvelle version de l'application.

## 0. Attendre que l'environnement soit prêt

`/root/wait-for-prep.sh`{{exec}}

Cette commande attend la fin de la préparation de l'environnement. Attends qu'elle affiche « C'est pret ! » avant de continuer.

`kubectl get deployments`{{exec}}

Tu dois voir `millennium-falcon`, `death-star` et `tie-fighter`.

## 1. Observer l'état actuel

`kubectl get deployment millennium-falcon -o jsonpath='{.spec.strategy}'`{{exec}}

Tu dois voir le type `Recreate`.

`kubectl get deployment millennium-falcon -o jsonpath='{.spec.template.spec.containers[0].env[0].value}'`{{exec}}

La variable `APP_RELEASE` vaut `v2`.

`kubectl rollout history deployment/millennium-falcon`{{exec}}

Il n'y a qu'une seule révision pour le moment.

## 2. Modifier le Deployment

Tu vas faire les deux modifications dans la même édition :

`kubectl edit deployment millennium-falcon`{{exec}}

**Modification n°1 : la stratégie.** Repère la section `strategy` (dans vi : tape `/strategy` puis `Entrée`). Elle ressemble à ceci :

```
  strategy:
    type: Recreate
```

Remplace-la par ceci :

```
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

- `maxSurge: 1` autorise un pod de plus que le nombre de réplicas souhaité pendant la mise à jour (jusqu'à 3 pods ici) ;
- `maxUnavailable: 0` interdit de passer sous le nombre de réplicas souhaité : il y a toujours 2 pods disponibles.

> Pour passer de `Recreate` à `RollingUpdate`, il faut ajouter le bloc `rollingUpdate`. Dans l'autre sens, ce bloc doit être supprimé : l'API refuse un bloc `rollingUpdate` avec la stratégie `Recreate`.

**Modification n°2 : la version.** Repère la variable d'environnement (dans vi : tape `/APP_RELEASE` puis `Entrée`) et change sa valeur de `v2` à `v3` :

```
        - name: APP_RELEASE
          value: "v3"
```

Quelques rappels sur vi :

- `i` passe en mode insertion, `Échap` en sort ;
- `x` supprime le caractère sous le curseur, `dd` supprime la ligne entière, `o` ouvre une nouvelle ligne sous la ligne courante ;
- l'indentation compte en YAML : utilise des espaces, jamais de tabulation.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

Si l'API refuse la modification, `kubectl edit` te le dit et te propose de corriger : relis ton indentation et tes valeurs.

Changer la variable modifie le pod template, ce qui déclenche un rollout. Comme les deux modifications sont enregistrées ensemble, ce rollout utilise déjà la nouvelle stratégie.

## 3. Suivre le rollout

`kubectl rollout status deployment/millennium-falcon`{{exec}}

Cette commande attend la fin du rollout et affiche sa progression. Quand elle rend la main, tous les pods ont été remplacés.

## 4. Observer le résultat

`kubectl get rs -l app=millennium-falcon`{{exec}}

L'ancien ReplicaSet est à 0 réplica et le nouveau à 2.

`kubectl rollout history deployment/millennium-falcon`{{exec}}

Il y a maintenant deux révisions : ton édition n'en a créé qu'une seule, car seule la modification du pod template (la variable) crée une révision. Le changement de stratégie, lui, n'en crée pas.

`kubectl describe deployment millennium-falcon`{{exec}}

Regarde la section `Events` en bas : les deux ReplicaSets montent et descendent par paliers d'un pod, au lieu que l'ancien soit supprimé d'un coup comme avec `Recreate`.
