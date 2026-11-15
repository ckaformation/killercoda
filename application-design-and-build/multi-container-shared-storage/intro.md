# Multi-container pods et stockage partagé

Les containers d'un même pod peuvent partager des fichiers grâce aux **volumes**. Tu vas fournir la page web de trois nginx de trois façons différentes.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud et un raccourci `k` (identique à `kubectl`).
- Dans le namespace `default`, trois Deployments identiques (`nginx:alpine`, 1 réplica), chacun décrit par un fichier dans `/root` :
  - `dagobah` : `/root/dagobah.yaml`
  - `x-wing` : `/root/x-wing.yaml`
  - `jedi-archives` : `/root/jedi-archives.yaml`
- Un PVC `holocron` (`Bound`, `ReadWriteOnce`, 100Mi) qui contient déjà une page web.

## Ce que tu vas faire

1. `dagobah` : un **init container** écrit la page dans un volume `emptyDir`, avant le démarrage de nginx.
2. `x-wing` : un **sidecar natif** réécrit la page chaque seconde, pendant que nginx la sert.
3. `jedi-archives` : nginx sert la page stockée sur le PVC `holocron`.
