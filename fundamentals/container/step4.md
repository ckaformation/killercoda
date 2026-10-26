# Étape 4 — Lancer une image d'un registre public

À l'étape précédente, le nom de l'image commençait par l'adresse du registre (`localhost:5000/...`). Pourtant, à l'étape 1, tu as écrit `FROM alpine`, et à l'étape 3 tu as lancé `registry:2` : aucun registre n'était indiqué.

Quand un nom d'image ne contient **pas** d'adresse de registre, Docker utilise par défaut **Docker Hub** (`docker.io`), le registre public de Docker. Ainsi :

| Nom court | Nom complet équivalent |
|---|---|
| `nginx:alpine` | `docker.io/library/nginx:alpine` |
| `alpine` | `docker.io/library/alpine:latest` |
| `registry:2` | `docker.io/library/registry:2` |

## 1. Lancer un conteneur nginx depuis Docker Hub

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
docker run -d -p 8080:80 --name <A_COMPLETER> nginx:alpine
```

Choisis le nom que tu veux, par exemple celui d'un personnage de Star Wars en minuscules. `-p 8080:80` publie le port 80 du conteneur (celui sur lequel écoute nginx) sur le port 8080 de la machine.

Observe la sortie : Docker télécharge plusieurs couches depuis `library/nginx` avant de démarrer le conteneur.

## 2. Vérifier que le conteneur tourne

`docker ps`{{exec}}

## 3. Interroger le serveur

`curl -s localhost:8080`{{exec}}

Tu dois obtenir la page d'accueil de nginx (`Welcome to nginx!`).

## 4. Comparer l'origine des images

`docker images`{{exec}}

Regarde le nom de chaque image (colonne `REPOSITORY`, ou `IMAGE` selon la version de Docker) :

- `nginx`, `alpine` et `registry` ont été téléchargées depuis Docker Hub, sans que tu précises de registre ;
- `localhost:5000/holocron` vient de ton registre local, et son nom l'indique.
