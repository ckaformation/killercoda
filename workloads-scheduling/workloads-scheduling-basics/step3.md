# Étape 3 — Incrémenter les révisions et faire un rollback

## 1. Première modification du pod template

Contrairement au scaling, modifier le **pod template** crée bien une nouvelle révision. On change la valeur de `SQUADRON_VERSION` :

`kubectl edit deployment x-wing-fleet`{{exec}}

Change `value: "v1"` en `value: "v2"` (dans la section `env`).

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`kubectl rollout status deployment/x-wing-fleet`{{exec}}

## 2. Deuxième modification du pod template

`kubectl edit deployment x-wing-fleet`{{exec}}

Change `value: "v2"` en `value: "v3"`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`kubectl rollout status deployment/x-wing-fleet`{{exec}}

## 3. Consulter l'historique

`kubectl rollout history deployment/x-wing-fleet`{{exec}}

Tu devrais voir 3 révisions : la création (révision 1), puis les deux modifications (révisions 2 et 3). Le scaling de l'étape 2 n'apparaît pas : il ne touchait pas le pod template.

## 4. Revenir 2 révisions en arrière

On est actuellement en révision 3 ; on veut revenir à la révision 1 (3 − 2) :

`kubectl rollout undo deployment/x-wing-fleet --to-revision=1`{{exec}}

`kubectl rollout status deployment/x-wing-fleet`{{exec}}

## 5. Vérifier

`k get pods -l app=x-wing-fleet -o jsonpath='{.items[0].spec.containers[0].env[0].value}'`{{exec}}

Doit afficher `v1` : le contenu de la révision 1 a bien été restauré.

`kubectl rollout history deployment/x-wing-fleet`{{exec}}

> Regarde bien les numéros affichés : tu ne verras **pas** réapparaître "1" en tête de liste. Kubernetes ne fait jamais "reculer" un numéro de révision — le rollback crée une **nouvelle** révision (la 4), dont le **contenu** correspond à l'ancienne révision 1. C'est le contenu qui est restauré, pas le numéro.
