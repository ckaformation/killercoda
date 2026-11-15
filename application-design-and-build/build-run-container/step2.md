# Étape 2 — Exporter et réimporter l'image

Une image peut voyager sans registry, dans une simple archive `.tar` : utile pour une machine sans accès réseau.

## 1. Exporter l'image

`podman save -o /root/r2d2.tar r2d2:v1`{{exec}}

`ls -lh /root/r2d2.tar`{{exec}}

`tar -tf /root/r2d2.tar`{{exec}}

L'archive contient les couches (`layer.tar`), la configuration de l'image (`.json`) et un `manifest.json`.

## 2. Supprimer l'image en local

Le container `r2d2` utilise l'image : supprime-le d'abord.

`podman rm -f r2d2`{{exec}}

Cela prend une dizaine de secondes : `ping`, PID 1 du container, ignore le signal `SIGTERM`, donc podman attend 10 secondes puis envoie `SIGKILL`.

`podman rmi r2d2:v1`{{exec}}

`podman images`{{exec}}

`localhost/r2d2` a disparu.

## 3. Réimporter l'image

`podman load -i /root/r2d2.tar`{{exec}}

`podman images`{{exec}}

`localhost/r2d2:v1` est de retour, avec le même `IMAGE ID` qu'à l'étape 1.
