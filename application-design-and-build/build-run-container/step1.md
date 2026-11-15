# Étape 1 — Écrire un Dockerfile, construire et lancer l'image

## 1. Attendre l'environnement

`/root/wait-for-prep.sh`{{exec}}

Attends qu'elle affiche « C'est pret ! » avant de continuer.

## 2. Écrire le Dockerfile

`mkdir -p /root/r2d2`{{exec}}

`cd /root/r2d2`{{exec}}

`vi Dockerfile`{{exec}}

Saisis ce contenu :

```
FROM bash
CMD ["ping", "127.0.0.1"]
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

- `FROM bash` : l'image de départ, l'image officielle `bash`. Ce nom court est résolu en `docker.io/library/bash`.
- `CMD` : la commande lancée au démarrage du container.

## 3. Construire l'image

`podman build -t r2d2:v1 .`{{exec}}

- `-t` : nom et tag de l'image (`nom:tag`).
- `.` : le contexte de build, ici le dossier courant qui contient le `Dockerfile`.

`podman images`{{exec}}

Podman préfixe les images construites en local par `localhost/` : `localhost/r2d2:v1`.

## 4. Lancer l'image

`podman run -d --name r2d2 --cap-add NET_RAW r2d2:v1`{{exec}}

- `-d` : en arrière-plan.
- `--cap-add NET_RAW` : `ping` a besoin de la capability Linux `NET_RAW`, que podman ne donne pas par défaut. Sans elle, le container s'arrête avec `ping: permission denied (are you root?)`.

`podman ps`{{exec}}

## 5. Lire les logs

`podman logs r2d2`{{exec}}

Tu vois les réponses : `64 bytes from 127.0.0.1: seq=0 ttl=64 ...`.
