# Étape 1 — Construire une image

Une **image** est un modèle en lecture seule (un système de fichiers plus des métadonnées) à partir duquel on crée des conteneurs. On la décrit dans un fichier `Dockerfile`, puis `docker build` la fabrique.

## 0. Vérifier que Docker est prêt

`docker version`{{exec}}

Tu dois voir une section `Client` **et** une section `Server`. Si la commande `docker` est introuvable, ou si la section `Server` est absente, la préparation de l'environnement n'est peut-être pas terminée : attends quelques secondes et relance la commande.

## 1. Observer le contenu à empaqueter

`cd /root/holocron`{{exec}}

`ls`{{exec}}

`cat message.txt`{{exec}}

C'est ce message que ton image devra afficher.

## 2. Écrire le Dockerfile

`vi Dockerfile`{{exec}}

Saisis exactement ce contenu, puis enregistre avec `:wq` :

```
FROM alpine
COPY message.txt /message.txt
CMD ["cat", "/message.txt"]
```

Chaque instruction a un rôle :

- `FROM alpine` : l'image de départ, ici une distribution Linux très légère ;
- `COPY message.txt /message.txt` : copie le fichier du dossier courant dans l'image ;
- `CMD ["cat", "/message.txt"]` : la commande exécutée **par défaut** quand on démarre un conteneur à partir de l'image.

`cat Dockerfile`{{exec}}

## 3. Construire l'image

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
docker build -t <A_COMPLETER> .
```

- `-t` donne un nom et un tag à l'image : utilise le nom `holocron` et le tag `v1`, au format `nom:tag` ;
- le `.` final indique le **contexte de build** : le dossier courant, dans lequel Docker ira chercher le `Dockerfile` et le fichier à copier.

## 4. Vérifier que l'image existe

`docker images`{{exec}}

Tu dois retrouver `holocron` avec le tag `v1` (affichés ensemble sous la forme `holocron:v1` avec les versions récentes de Docker), ainsi que `alpine`, l'image de base que Docker a téléchargée pour construire la tienne.
