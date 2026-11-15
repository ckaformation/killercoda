# Étape 4 — Lancer l'image dans Kubernetes

Kubernetes ne voit pas les images stockées par podman : containerd, le runtime du cluster, a son propre stockage. Il va donc télécharger l'image depuis la registry.

## 1. Créer le pod

`k run r2d2 --image=localhost:5000/r2d2:v1`{{exec}}

`k get pods`{{exec}}

Le pod doit être `Running`. S'il est encore en `ContainerCreating`, relance la commande.

Pas besoin d'ajouter `NET_RAW` ici : containerd accorde cette capability par défaut aux containers.

## 2. Suivre les logs

`k logs -f r2d2`{{exec}}

Les réponses du ping défilent en continu. Quitte avec `Ctrl+C`.
