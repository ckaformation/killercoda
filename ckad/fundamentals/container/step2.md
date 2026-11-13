# Étape 2 — Lancer un conteneur et lister les conteneurs

Un **conteneur** est une instance, en cours d'exécution ou terminée, d'une image. Tu peux en créer autant que tu veux à partir de la même image.

## 1. Lancer un premier conteneur

`docker run holocron:v1`{{exec}}

Le conteneur exécute la commande par défaut de l'image (le `CMD` du Dockerfile), affiche le message, puis **s'arrête** : un conteneur ne vit que tant que son processus principal tourne, et ici `cat` se termine immédiatement.

## 2. Lister les conteneurs en cours d'exécution

`docker ps`{{exec}}

La liste est vide : ton conteneur n'est plus en cours d'exécution.

## 3. Lister tous les conteneurs, y compris ceux qui sont terminés

`docker ps -a`{{exec}}

Observe la ligne de ton conteneur :

- `IMAGE` : `holocron:v1`, l'image dont il est issu ;
- `STATUS` : `Exited (0) ...` ; le code `0` signifie « terminé sans erreur » ;
- `NAMES` : un nom généré au hasard par Docker, puisque tu n'en as pas choisi.

## 4. Lancer un conteneur qui reste en vie

Tout ce qui suit le nom de l'image dans `docker run` **remplace** le `CMD` de l'image. En le remplaçant par `sleep 3600`, le conteneur reste actif pendant une heure. L'option `-d` (detach) le lance en arrière-plan, et `--name` lui donne un nom.

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
docker run -d --name <A_COMPLETER> holocron:v1 sleep 3600
```

Choisis le nom que tu veux, par exemple celui d'un personnage de Star Wars en minuscules.

## 5. Comparer `docker ps` et `docker ps -a`

`docker ps`{{exec}}

`docker ps -a`{{exec}}

Cette fois, `docker ps` affiche ton nouveau conteneur (`Up ...`), alors que `docker ps -a` affiche les deux : celui qui a tourné puis s'est arrêté, et celui qui tourne encore.
