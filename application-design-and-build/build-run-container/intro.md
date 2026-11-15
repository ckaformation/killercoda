# Build et run d'un container

R2-D2 émet ses bips sans jamais s'arrêter. Tu vas l'enfermer dans une image : un container qui envoie un `ping` en boucle vers `127.0.0.1`, de sa construction jusqu'à son lancement dans Kubernetes.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud et un raccourci `k` (identique à `kubectl`).
- `podman`, installé sur le nœud.
- Une registry locale, `jedi-archives` : un container podman qui écoute sur `localhost:5000`.

## Ce que tu vas faire

1. Écrire un `Dockerfile`, construire l'image avec `podman build`, la lancer avec `podman run` et lire ses logs.
2. Exporter l'image dans une archive `.tar` avec `podman save`, puis la réimporter avec `podman load`.
3. Tagger l'image pour la registry locale et l'y pousser avec `podman push`.
4. Lancer l'image depuis la registry dans un pod Kubernetes et suivre ses logs.
