# Bravo !

R2-D2 a fait tout le voyage :

1. **Build** : un `Dockerfile` de deux lignes, `podman build`, puis `podman run` et `podman logs`.
2. **Archive** : `podman save` vers `/root/r2d2.tar`, puis `podman load` après suppression de l'image.
3. **Registry** : `podman tag` puis `podman push` vers `localhost:5000`.
4. **Kubernetes** : `k run` avec l'image de la registry, puis `k logs -f`.

## Points clés à retenir

- `FROM` choisit l'image de départ, `CMD` la commande lancée au démarrage du container.
- `podman build -t nom:tag .` : le `.` est le contexte de build, le dossier qui contient le `Dockerfile`.
- `podman save -o fichier.tar image` et `podman load -i fichier.tar` déplacent une image sans registry.
- Pour pousser vers une registry, le nom de l'image commence par son adresse : `localhost:5000/r2d2:v1`. `podman tag` ajoute un nom sans copier l'image.
- Une registry sans TLS doit être déclarée `insecure` (ou utilisée avec `--tls-verify=false`).
- Le cluster ne voit pas les images locales de podman : il les télécharge depuis une registry.
- Les capabilities Linux par défaut dépendent du runtime : podman ne donne pas `NET_RAW`, containerd si. Dans un pod, on les ajuste avec `securityContext.capabilities`.

## Pour aller plus loin

- Images dans Kubernetes : https://kubernetes.io/docs/concepts/containers/images/
- Security context (dont les capabilities) : https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- `kubectl run` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_run/
